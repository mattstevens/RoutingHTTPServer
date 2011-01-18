#import <Foundation/Foundation.h>
#import "HTTPResponse.h"
@class HTTPConnection;


@interface RouteResponse : NSObject {
	HTTPConnection *connection;
	NSMutableDictionary *headers;
	NSObject<HTTPResponse> *response;
}

@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, retain) NSObject<HTTPResponse> *response;

- (id)initWithConnection:(HTTPConnection *)theConnection;
- (void)setHeader:(NSString *)field value:(NSString *)value;
- (void)respondWithString:(NSString *)string;
- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)respondWithData:(NSData *)data;
- (void)respondWithFile:(NSString *)path async:(BOOL)async;

@end
