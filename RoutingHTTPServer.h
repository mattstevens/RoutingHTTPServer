#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "RouteRequest.h"
#import "RouteResponse.h"


@interface RoutingHTTPServer : HTTPServer {
	NSMutableDictionary *routes;
	NSMutableDictionary *defaultHeaders;
}

typedef void (^RequestHandler)(RouteRequest *request, RouteResponse *response);

@property (nonatomic, readonly) NSDictionary *defaultHeaders;

- (void)setDefaultHeaders:(NSDictionary *)headers;
- (void)setDefaultHeader:(NSString *)field value:(NSString *)value;

// Convenience methods. Yes I know, this is Cocoa and we don't use convenience
// methods because typing lengthy primitives over and over and over again is
// elegant with the beauty and the poetry. These are just, you know, here.
- (void)get:(NSString *)path withBlock:(RequestHandler)block;
- (void)post:(NSString *)path withBlock:(RequestHandler)block;
- (void)handleGet:(NSString *)path withBlock:(RequestHandler)block;
- (void)handlePost:(NSString *)path withBlock:(RequestHandler)block;
- (void)handlePut:(NSString *)path withBlock:(RequestHandler)block;
- (void)handleDelete:(NSString *)path withBlock:(RequestHandler)block;
- (void)handleSubscribe:(NSString *)path withBlock:(RequestHandler)block;
- (void)handleUnsubscribe:(NSString *)path withBlock:(RequestHandler)block;

- (void)handleMethod:(NSString *)method withPath:(NSString *)path block:(RequestHandler)block;
- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target selector:(SEL)selector;

- (BOOL)supportsMethod:(NSString *)method;
- (RouteResponse *)routeMethod:(NSString *)method withPath:(NSString *)path parameters:(NSDictionary *)params request:(HTTPMessage *)request connection:(HTTPConnection *)connection;

@end
