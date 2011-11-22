#import "AppDelegate.h"
#import "RoutingHTTPServer.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize http;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.http = [[[RoutingHTTPServer alloc] init] autorelease];
	
	// Set a default Server header in the form of YourApp/1.0
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
	if (!appVersion) {
		appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
	}
	NSString *serverHeader = [NSString stringWithFormat:@"%@/%@",
							  [bundleInfo objectForKey:@"CFBundleName"],
							  appVersion];
	[http setDefaultHeader:@"Server" value:serverHeader];
	
	[self setupRoutes];
	[http setPort:8080];
	[http setDocumentRoot:[@"~/Sites" stringByExpandingTildeInPath]];
	
	NSError *error;
	if (![http start:&error]) {
		NSLog(@"Error starting HTTP Server: %@", error);
	}
}

- (void)setupRoutes {
	[http get:@"/hello" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:@"Hello!"];
	}];
	
	[http get:@"/hello/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"Hello %@!", [request param:@"name"]]];
	}];
	
	[http get:@"{^/page/(\\d+)}" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"You requested page %@",
									 [[request param:@"captures"] objectAtIndex:0]]];
	}];
}

@end
