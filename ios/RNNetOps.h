
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import "wol.h"
#import "SimplePing.h"
#import "poke.h"

@interface RNNetOps : NSObject <RCTBridgeModule>, SimplePingDelegate>

@property (nonatomic, strong, readwrite, nullable) SimplePing* pinger;
@property (nonatomic, strong, readwrite, nullable) RCTResponseSenderBlock callback;
@property (nonatomic, strong, readwrite, nullable) NSTimer* sendTimer;
@property (nonatomic, strong, readwrite, nonnull) NSNumber* timeout;

@end