#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"

@interface Route : NSObject {
	NSRegularExpression *regex;
	RequestHandler handler;
	__weak id target;
	SEL selector;
	NSArray *keys;
}

@property (nonatomic) NSRegularExpression *regex;
@property (nonatomic, copy) RequestHandler handler;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic) NSArray *keys;

@end
