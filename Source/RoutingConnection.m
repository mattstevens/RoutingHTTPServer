#import "RoutingConnection.h"
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPResponseProxy.h"


@implementation RoutingConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
	if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
		NSAssert([config.server isKindOfClass:[RoutingHTTPServer class]],
				 @"A RoutingConnection is being used with a server that is not a RoutingHTTPServer");

		http = (RoutingHTTPServer *)config.server;
	}
	return self;
}

- (void)dealloc {
	[headers release];
	[super dealloc];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {

	if ([http supportsMethod:method])
		return YES;

	return [super supportsMethod:method atPath:path];
}

- (void)processDataChunk:(NSData *)postDataChunk {
	BOOL result = [request appendData:postDataChunk];
	if (!result) {
		// TODO: Log
	}
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSURL *url = [request url];
	NSString *query = nil;
	NSDictionary *params = [NSDictionary dictionary];
	[headers release];
	headers = nil;

	if (url) {
		path = [url path]; // Strip the query string from the path
		query = [url query];
		if (query) {
			params = [self parseParams:query];
		}
	}

	RouteResponse *response = [http routeMethod:method withPath:path parameters:params request:request connection:self];
	if (response != nil) {
		headers = [response.headers retain];
		return response.proxiedResponse;
	}

	return [super httpResponseForMethod:method URI:path];
}

- (void)responseHasAvailableData:(NSObject<HTTPResponse> *)sender {
	HTTPResponseProxy *proxy = (HTTPResponseProxy *)httpResponse;
	if (proxy.response == sender) {
		[super responseHasAvailableData:httpResponse];
	}
}

- (void)responseDidAbort:(NSObject<HTTPResponse> *)sender {
	HTTPResponseProxy *proxy = (HTTPResponseProxy *)httpResponse;
	if (proxy.response == sender) {
		[super responseDidAbort:httpResponse];
	}
}

- (void)setHeadersForResponse:(HTTPMessage *)response isError:(BOOL)isError {
	[http.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
		[response setHeaderField:field value:value];
	}];

	if (headers && !isError) {
		[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
			[response setHeaderField:field value:value];
		}];
	}

	// Set the connection header if not already specified
	NSString *connection = [response headerField:@"Connection"];
	if (!connection) {
		connection = [self shouldDie] ? @"close" : @"keep-alive";
		[response setHeaderField:@"Connection" value:connection];
	}
}

- (NSData *)preprocessResponse:(HTTPMessage *)response {
	[self setHeadersForResponse:response isError:NO];
	return [super preprocessResponse:response];
}

- (NSData *)preprocessErrorResponse:(HTTPMessage *)response {
	[self setHeadersForResponse:response isError:YES];
	return [super preprocessErrorResponse:response];
}

- (BOOL)shouldDie {
	__block BOOL shouldDie = [super shouldDie];

	// Allow custom headers to determine if the connection should be closed
	if (!shouldDie && headers) {
		[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
			if ([field caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
				if ([value caseInsensitiveCompare:@"close"] == NSOrderedSame) {
					shouldDie = YES;
				}
				*stop = YES;
			}
		}];
	}

	return shouldDie;
}

@end
