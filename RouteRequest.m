#import "RouteRequest.h"
#import "HTTPMessage.h"


@implementation RouteRequest

@synthesize parameters;

- (id)initWithHTTPMessage:(HTTPMessage *)msg parameters:(NSDictionary *)params {
	if (self = [super init]) {
		parameters = [params retain];
		message = [msg retain];
	}
	return self;
}

- (void)dealloc {
	[parameters release];
	[message release];
	[super dealloc];
}

- (NSDictionary *)headers {
	return [message allHeaderFields];
}

- (NSString *)valueForHeader:(NSString *)field {
	return [message headerField:field];
}

- (NSString *)method {
	return [message method];
}

- (NSURL *)url {
	return [message url];
}

- (NSData *)body {
	return [message body];
}

- (NSString *)description {
	NSData *data = [message messageData];
	return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

@end
