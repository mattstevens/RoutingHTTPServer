#import <Cocoa/Cocoa.h>
@class RoutingHTTPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (retain) RoutingHTTPServer *http;

- (void)setupRoutes;

@end
