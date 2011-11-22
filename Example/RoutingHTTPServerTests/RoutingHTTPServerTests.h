#import <SenTestingKit/SenTestingKit.h>
@class RoutingHTTPServer;

@interface RoutingHTTPServerTests : SenTestCase {
	RoutingHTTPServer *http;
}

- (void)setupRoutes;
- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path expectedResponse:(NSString *)expectedResponse;

@end
