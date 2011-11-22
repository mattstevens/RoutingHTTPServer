#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"


@interface Route : NSObject {
	NSRegularExpression *regex;
	RequestHandler handler;
	id target;
	SEL selector;
	NSArray *keys;
}

@property (nonatomic, retain) NSRegularExpression *regex;
@property (nonatomic, copy) RequestHandler handler;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, retain) NSArray *keys;

@end
