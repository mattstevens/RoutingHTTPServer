#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
@class RoutingHTTPServer;

@interface RoutingConnection : HTTPConnection {
	__weak RoutingHTTPServer *http;
	NSDictionary *headers;
}

@end
