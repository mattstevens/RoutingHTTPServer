#import "Route.h"


@implementation Route

@synthesize path;
@synthesize handler;
@synthesize target;
@synthesize selector;
@synthesize keys;

- (void)dealloc {
	self.path = nil;
	self.keys = nil;
	self.handler = nil;
	[super dealloc];
}

- (void)setHandler:(RequestHandler)newHandler {
	if (newHandler)
		newHandler = Block_copy(newHandler);

	if (handler)
		Block_release(handler);

	handler = newHandler;
}

@end
