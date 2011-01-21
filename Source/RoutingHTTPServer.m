#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
#import "Route.h"
#import "RegexKitLite.h"

@interface RoutingHTTPServer ()

- (Route *)routeWithPath:(NSString *)path;
- (void)addRoute:(Route *)route forMethod:(NSString *)method;

@end

@implementation RoutingHTTPServer

@synthesize defaultHeaders;

- (id)init {
	if (self = [super init]) {
		connectionClass = [RoutingConnection self];
		routes = [[NSMutableDictionary alloc] init];
		defaultHeaders = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	if (routeQueue)
		dispatch_release(routeQueue);

	[routes release];
	[defaultHeaders release];
	[super dealloc];
}

- (void)setDefaultHeaders:(NSDictionary *)headers {
	NSMutableDictionary *newHeaders;
	if (headers) {
		newHeaders = [headers mutableCopy];
	} else {
		newHeaders = [[NSMutableDictionary alloc] init];
	}

	if (defaultHeaders) {
		[defaultHeaders release];
	}
	defaultHeaders = newHeaders;
}

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value {
	[defaultHeaders setObject:value forKey:field];
}

- (dispatch_queue_t)routeQueue {
	return routeQueue;
}

- (void)setRouteQueue:(dispatch_queue_t)queue {
	if (queue)
		dispatch_retain(queue);

	if (routeQueue)
		dispatch_release(routeQueue);

	routeQueue = queue;
}

- (void)get:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"GET" withPath:path block:block];
}

- (void)post:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"POST" withPath:path block:block];
}

- (void)put:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"PUT" withPath:path block:block];
}

- (void)delete:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"DELETE" withPath:path block:block];
}

- (void)subscribe:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"SUBSCRIBE" withPath:path block:block];
}

- (void)unsubscribe:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"UNSUBSCRIBE" withPath:path block:block];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path block:(RequestHandler)block {
	Route *route = [self routeWithPath:path];
	route.handler = block;

	[self addRoute:route forMethod:method];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target selector:(SEL)selector {
	Route *route = [self routeWithPath:path];
	route.target = target;
	route.selector = selector;

	[self addRoute:route forMethod:method];
}

- (void)addRoute:(Route *)route forMethod:(NSString *)method {
	method = [method uppercaseString];
	NSMutableArray *methodRoutes = [routes objectForKey:method];
	if (methodRoutes == nil) {
		methodRoutes = [NSMutableArray array];
		[routes setObject:methodRoutes forKey:method];
	}

	[methodRoutes addObject:route];

	// Define a HEAD route for all GET routes
	if ([method isEqualToString:@"GET"]) {
		[self addRoute:route forMethod:@"HEAD"];
	}
}

- (Route *)routeWithPath:(NSString *)path {
	Route *route = [[[Route alloc] init] autorelease];
	NSMutableArray *keys = [NSMutableArray array];

	if ([path length] > 2 && [path characterAtIndex:0] == '{') {
		// This is a custom regular expression, just remove the {}
		path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
	} else {
		// Escape regex characters
		path = [path stringByReplacingOccurrencesOfRegex:@"[.+()]" usingBlock:
				^NSString *(NSInteger captureCount, NSString *const capturedStrings[captureCount], const NSRange capturedRanges[captureCount], volatile BOOL *const stop) {
					return [NSString stringWithFormat:@"\\%@", capturedStrings[0]];
				}];

		// Parse any :parameters in the path
		path = [path stringByReplacingOccurrencesOfRegex:@"(:(\\w+)|\\*)" usingBlock:
				^NSString *(NSInteger captureCount, NSString *const capturedStrings[captureCount], const NSRange capturedRanges[captureCount], volatile BOOL *const stop) {
					if ([capturedStrings[1] isEqualToString:@"*"]) {
						[keys addObject:@"wildcards"];
						return @"(.*?)";
					}

					[keys addObject:capturedStrings[2]];
					return @"([^/]+)";
				}];

		path = [NSString stringWithFormat:@"^%@$", path];
	}

	route.path = path;
	if ([keys count] > 0) {
		route.keys = keys;
	}

	return route;
}

- (BOOL)supportsMethod:(NSString *)method {
	return ([routes objectForKey:method] != nil);
}

- (void)handleRoute:(Route *)route withRequest:(RouteRequest *)request response:(RouteResponse *)response {
	if (route.handler) {
		route.handler(request, response);
	} else {
		[route.target performSelector:route.selector withObject:request withObject:response];
	}
}

- (RouteResponse *)routeMethod:(NSString *)method withPath:(NSString *)path parameters:(NSDictionary *)params request:(HTTPMessage *)httpMessage connection:(HTTPConnection *)connection {
	NSMutableArray *methodRoutes = [routes objectForKey:method];
	if (methodRoutes == nil)
		return nil;

	for (Route *route in methodRoutes) {
		// The first element in the captures array is all of the text matched by the regex.
		// If there is nothing in the array the regex did not match.
		NSArray *captures = [path captureComponentsMatchedByRegex:route.path];
		if ([captures count] < 1)
			continue;

		if (route.keys) {
			// Add the route's parameters to the parameter dictionary, accounting for
			// the first element containing the matched text.
			if ([captures count] == [route.keys count] + 1) {
				NSMutableDictionary *newParams = [[params mutableCopy] autorelease];
				NSUInteger index = 1;
				BOOL firstWildcard = YES;
				for (NSString *key in route.keys) {
					NSString *capture = [captures objectAtIndex:index];
					if ([key isEqualToString:@"wildcards"]) {
						NSMutableArray *wildcards = [newParams objectForKey:key];
						if (firstWildcard) {
							// Create a new array and replace any existing object with the same key
							wildcards = [NSMutableArray array];
							[newParams setObject:wildcards forKey:key];
							firstWildcard = NO;
						}
						[wildcards addObject:capture];
					} else {
						[newParams setObject:capture forKey:key];
					}
					index++;
				}
				params = newParams;
			}
		} else if ([captures count] > 1) {
			// For custom regular expressions place the anonymous captures in the captures parameter
			NSMutableDictionary *newParams = [[params mutableCopy] autorelease];
			[newParams setObject:[captures subarrayWithRange:NSMakeRange(1, [captures count] - 1)] forKey:@"captures"];
			params = newParams;
		}

		RouteRequest *request = [[[RouteRequest alloc] initWithHTTPMessage:httpMessage parameters:params] autorelease];
		RouteResponse *response = [[[RouteResponse alloc] initWithConnection:connection] autorelease];
		if (!routeQueue) {
			[self handleRoute:route withRequest:request response:response];
		} else {
			// Process the route on the specified queue
			__block RoutingHTTPServer *blockSelf = self;
			dispatch_sync(routeQueue, ^{
				[blockSelf handleRoute:route withRequest:request response:response];
			});
		}
		return response;
	}

	return nil;
}

@end
