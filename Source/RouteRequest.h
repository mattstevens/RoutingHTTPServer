#import <Foundation/Foundation.h>
@class HTTPMessage;


@interface RouteRequest : NSObject {
	NSDictionary *parameters;
	HTTPMessage *message;
}

@property (nonatomic, readonly) NSDictionary *parameters;

- (id)initWithHTTPMessage:(HTTPMessage *)msg parameters:(NSDictionary *)params;
- (NSString *)valueForHeader:(NSString *)field;
- (NSString *)method;
- (NSURL *)url;
- (NSData *)body;

@end
