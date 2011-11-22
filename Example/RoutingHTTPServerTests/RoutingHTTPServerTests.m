#import "RoutingHTTPServerTests.h"
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"

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
	
	[self verifyRouteWithMethod:@"GET" path:@"/hello" expectedResponse:@"/hello"];
	[self verifyRouteWithMethod:@"GET" path:@"/hello/you" expectedResponse:@"/hello/you"];
	[self verifyRouteWithMethod:@"GET" path:@"/page/3" expectedResponse:@"/page/3"];
	[self verifyRouteWithMethod:@"POST" path:@"/form" expectedResponse:@"/form"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob" expectedResponse:@"/users/bob"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob/dosomething" expectedResponse:@"/users/bob/dosomething"];
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
	
	[http get:@"{^/page/(\\d+)}" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/page/%@",
									 [[request param:@"captures"] objectAtIndex:0]]];
	}];
}

- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path expectedResponse:(NSString *)expectedResponse {
	RouteResponse *response;
	NSDictionary *params = [NSDictionary dictionary];
	HTTPMessage *request = [[[HTTPMessage alloc] initEmptyRequest] autorelease];
	
	response = [http routeMethod:method withPath:path parameters:params request:request connection:nil];
	STAssertNotNil(response.proxiedResponse, @"Proxied response is nil for %@ %@", method, path);
	
	NSUInteger length = [response.proxiedResponse contentLength];
	NSData *data = [response.proxiedResponse readDataOfLength:length];
	NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	STAssertEqualObjects(responseString, expectedResponse, @"Unexpected response for %@ %@", method, path);
}

@end
