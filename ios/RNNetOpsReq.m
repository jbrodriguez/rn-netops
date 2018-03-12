#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import "RNNetOps.h"
#import "RNNetOpsReq.h"

@implementation RNNetOpsReq

@synthesize url;
@synthesize options;
@synthesize callback;
@synthesize destPath;


- (NSString *)md5:(NSString *)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}


- (NSMutableURLRequest *)createRequest:(NSString *)url 
		method:(NSString *)method
		headers:(NSDictionary *)headers 
		body:(NSString *)body
{
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
		initWithURL:[NSURL URLWithString:url]
		cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
		timeoutInterval:60];

	// set method and headers
	[request setHTTPMethod:method];
	[request setAllHTTPHeaderFields:headers];

	if (body != nil) {
		[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	}

	return request;
}


- (NSURLSession *)createSession:(float) timeout
{
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

	// set session timeout
	if(timeout > 0) {
		config.timeoutIntervalForRequest = timeout/1000;
	}
	config.HTTPMaximumConnectionsPerHost = 10;

	// create session
	NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
	return session;
}

// send HTTP request
- (void) sendRequest:(NSString *)url 
		options:(NSDictionary *)options
		callback:(RCTResponseSenderBlock) callback
{
	self.url = url;
	self.options = options;
	self.callback = callback;

	NSString * method = [self.options valueForKey:@"method"];
	NSDictionary * headers = [self.options valueForKey:@"headers"];
	NSString * body = [self.options valueForKey:@"body"];
	BOOL cacheImage = [self.options valueForKey:@"cacheImage"];
	float timeout = [self.options valueForKey:@"timeout"] == nil ? -1 : [[options valueForKey:@"timeout"] floatValue];
	
	// use a downloadtask here
	if(cacheImage) {
		NSString *cacheKey = [self md5:self.url];

		// get filename
   		NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    	NSString *filename = [NSString stringWithFormat:@"/rnno_%@.png", cacheKey];
		self.destPath = [documentDir stringByAppendingString: filename];

		if ([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
			self.callback(@[[NSNull null], @0, self.destPath]);
			return;
		}

		// since it isn't cached yet, actually download the image
		// create request & session
		NSMutableURLRequest *request = [self createRequest:self.url method:method headers:headers body:nil];
		NSURLSession *session = [self createSession:timeout];

		// create DownloadTask with completion handler
		// this stores the file in a temp location, that  can be moved to a permanent location
		// it will invoke didReceiveChallenge delegate, to handle trusty stuff
		NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
			completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
				if (error) {
					NSDictionary *exception = @{@"code":@1, @"message":[NSString stringWithFormat:@"Unable to download image. %@", error]};
					self.callback(@[exception, @1, [NSNull null]]);
					return;
				}

				NSURL *documents = [NSURL URLWithString:[@"file://" stringByAppendingString:documentDir]];
				NSURL *permanent = [documents URLByAppendingPathComponent:filename];

				NSFileManager *fm = [NSFileManager defaultManager];
				NSError *err = nil;

				[fm moveItemAtURL:location toURL:permanent error:&err];
				if (err) {
					NSLog(@"Unable to move temporary file to destination:(%@)", err);
					NSDictionary *exception = @{@"code":@2, @"message":[NSString stringWithFormat:@"Unable to move temporary file to destination. %@", err]};
					self.callback(@[exception, @2, [NSNull null]]);
					return;
				}

				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
				self.callback(@[[NSNull null], [NSNumber numberWithLong:[httpResponse statusCode]], self.destPath]);
			}
		];

		// actual network request
		[downloadTask resume];
		return;
	}

	// use a datatask here
	NSMutableURLRequest *request = [self createRequest:self.url method:method headers:headers body:body];
	NSURLSession *session = [self createSession:timeout];

	// create DataTask with completion handler
	// it will invoke didReceiveChallenge delegate, to handle trusty stuff
	NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
		completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (error) {
				NSDictionary *exception = @{@"code":@3, @"message":[NSString stringWithFormat:@"Unable to get data(%@)", error]};
				self.callback(@[exception, @3, [NSNull null]]);
				return;
			}

			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

			NSString *reply = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			self.callback(@[[NSNull null], [NSNumber numberWithLong:[httpResponse statusCode]], reply]);				
		}
	];

	// actual network request
	[dataTask resume];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
   BOOL trusty = [self.options valueForKey:@"trusty"];
    if(!trusty) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
}

@end