#import "RouteResponse.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "HTTPAsyncFileResponse.h"


@implementation RouteResponse

@synthesize headers;
@synthesize response;

- (id)initWithConnection:(HTTPConnection *)theConnection {
	if (self = [super init]) {
		connection = theConnection;
		headers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	self.response = nil;
	[headers release];
	[super dealloc];
}

- (void)setHeader:(NSString *)field value:(NSString *)value {
	[headers setObject:value forKey:field];
}

- (void)respondWithString:(NSString *)string {
	[self respondWithString:string encoding:NSUTF8StringEncoding];
}

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
	[self respondWithData:[string dataUsingEncoding:encoding]];
}

- (void)respondWithData:(NSData *)data {
	self.response = [[[HTTPDataResponse alloc] initWithData:data] autorelease];
}

- (void)respondWithFile:(NSString *)path async:(BOOL)async {
	if (async) {
		self.response = [[[HTTPAsyncFileResponse alloc] initWithFilePath:path forConnection:connection] autorelease];
	} else {
		self.response = [[[HTTPFileResponse alloc] initWithFilePath:path forConnection:connection] autorelease];
	}
}

@end
