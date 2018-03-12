#import <Foundation/Foundation.h>

#ifndef RNNetOpsReq_h
#define RNNetOpsReq_h

@interface RNNetOpsReq : NSObject  <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nullable, nonatomic) NSString * url;
@property (nullable, nonatomic) NSDictionary * options;
@property (nullable, strong, nonatomic) RCTResponseSenderBlock callback;
@property (nullable, nonatomic) NSString * destPath;

- (void) sendRequest:(NSString * _Nullable)url options:(NSDictionary * _Nullable)options callback:(_Nullable RCTResponseSenderBlock) callback;

@end

#endif /* RNNetOpsReq_h */