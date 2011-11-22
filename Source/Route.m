#import "Route.h"


@implementation Route

@synthesize regex;
@synthesize handler;
@synthesize target;
@synthesize selector;
@synthesize keys;

- (void)dealloc {
	self.regex = nil;
	self.keys = nil;
	self.handler = nil;
	[super dealloc];
}

@end
