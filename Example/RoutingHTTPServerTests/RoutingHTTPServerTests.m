#import "RoutingHTTPServerTests.h"
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"

@interface RoutingHTTPServerTests ()

- (void)setupRoutes;
- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path;
- (void)verifyRouteNotFoundWithMethod:(NSString *)method path:(NSString *)path;
- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response;

@end

@implementation RoutingHTTPServerTests

- (void)setUp {
	[super setUp];
	http = [[RoutingHTTPServer alloc] init];
	[self setupRoutes];
}

- (void)tearDown {
	[http release];
	[super tearDown];
}

- (void)testRoutes {
	RouteResponse *response;
	NSDictionary *params = [NSDictionary dictionary];
	HTTPMessage *request = [[[HTTPMessage alloc] initEmptyRequest] autorelease];

	response = [http routeMethod:@"GET" withPath:@"/null" parameters:params request:request connection:nil];
	STAssertNil(response, @"Received response for path that does not exist");

	[self verifyRouteWithMethod:@"GET" path:@"/hello"];
	[self verifyRouteWithMethod:@"GET" path:@"/hello/you"];
	[self verifyRouteWithMethod:@"GET" path:@"/page/3"];
	[self verifyRouteWithMethod:@"GET" path:@"/files/test.txt"];
	[self verifyRouteWithMethod:@"GET" path:@"/selector"];
	[self verifyRouteWithMethod:@"POST" path:@"/form"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob/dosomething"];

	[self verifyRouteNotFoundWithMethod:@"POST" path:@"/hello"];
	[self verifyRouteNotFoundWithMethod:@"POST" path:@"/selector"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/a3"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/3a"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/form"];
}

- (void)setupRoutes {
	[http get:@"/hello" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:@"/hello"];
	}];

	[http get:@"/hello/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/hello/%@", [request param:@"name"]]];
	}];

	[http post:@"/form" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:@"/form"];
	}];

	[http post:@"/users/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/users/%@", [request param:@"name"]]];
	}];

	[http post:@"/users/:name/:action" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/users/%@/%@",
									 [request param:@"name"],
									 [request param:@"action"]]];
	}];

	[http get:@"{^/page/(\\d+)$}" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/page/%@",
									 [[request param:@"captures"] objectAtIndex:0]]];
	}];

	[http get:@"/files/*.*" withBlock:^(RouteRequest *request, RouteResponse *response) {
		NSArray *wildcards = [request param:@"wildcards"];
		[response respondWithString:[NSString stringWithFormat:@"/files/%@.%@",
									 [wildcards objectAtIndex:0],
									 [wildcards objectAtIndex:1]]];
	}];

	[http handleMethod:@"GET" withPath:@"/selector" target:self selector:@selector(handleSelectorRequest:withResponse:)];
}

- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response {
	[response respondWithString:@"/selector"];
}

- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path {
	RouteResponse *response;
	NSDictionary *params = [NSDictionary dictionary];
	HTTPMessage *request = [[[HTTPMessage alloc] initEmptyRequest] autorelease];

	response = [http routeMethod:method withPath:path parameters:params request:request connection:nil];
	STAssertNotNil(response.proxiedResponse, @"Proxied response is nil for %@ %@", method, path);

	NSUInteger length = [response.proxiedResponse contentLength];
	NSData *data = [response.proxiedResponse readDataOfLength:length];
	NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	STAssertEqualObjects(responseString, path, @"Unexpected response for %@ %@", method, path);
}

- (void)verifyRouteNotFoundWithMethod:(NSString *)method path:(NSString *)path {
	RouteResponse *response;
	NSDictionary *params = [NSDictionary dictionary];
	HTTPMessage *request = [[[HTTPMessage alloc] initEmptyRequest] autorelease];

	response = [http routeMethod:method withPath:path parameters:params request:request connection:nil];
	STAssertNil(response, @"Response should have been nil for %@ %@", method, path);
}

@end
