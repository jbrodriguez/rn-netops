
#import <React/RCTBridgeModule.h>

#import "wol.h"
#import "SimplePing.h"
#import "poke.h"

#ifndef RNNetOps_h
#define RNNetOps_h

@interface RNNetOps : NSObject <RCTBridgeModule, SimplePingDelegate>

@property (nonatomic, strong, readwrite, nullable) SimplePing* pinger;
@property (nonatomic, strong, readwrite, nullable) RCTResponseSenderBlock callback;
@property (nonatomic, strong, readwrite, nullable) NSTimer* sendTimer;
@property (nonatomic, strong, readwrite, nonnull) NSNumber* timeout;

@end

#endif /* RNNetOps_h */