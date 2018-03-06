
#import "RNNetOps.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/socket.h>
#import <netdb.h>

@import SystemConfiguration.CaptiveNetwork;

/*! Returns the string representation of the supplied address.
 *  \param address Contains a (struct sockaddr) with the address to render.
 *  \returns A string representation of that address.
 */

static NSString * displayAddressForAddress(NSData * address) {
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];

    result = nil;

    if (address != nil) {
        err = getnameinfo(address.bytes, (socklen_t) address.length, hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = @(hostStr);
        }
    }

    if (result == nil) {
        result = @"?";
    }

    return result;
}

/*! Returns a short error string for the supplied error.
 *  \param error The error to render.
 *  \returns A short string representing that error.
 */

static NSString * shortErrorFromError(NSError * error) {
    NSString *      result;
    NSNumber *      failureNum;
    int             failure;
    const char *    failureStr;

    assert(error != nil);

    result = nil;

    // Handle DNS errors as a special case.

    if ( [error.domain isEqual:(NSString *)kCFErrorDomainCFNetwork] && (error.code == kCFHostErrorUnknown) ) {
        failureNum = error.userInfo[(id) kCFGetAddrInfoFailureKey];
        if ( [failureNum isKindOfClass:[NSNumber class]] ) {
            failure = failureNum.intValue;
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = @(failureStr);
                }
            }
        }
    }

    // Otherwise try various properties of the error object.

    if (result == nil) {
        result = error.localizedFailureReason;
    }
    if (result == nil) {
        result = error.localizedDescription;
    }
    assert(result != nil);
    return result;
}

@implementation RNNetOps

// - (dispatch_queue_t)methodQueue
// {
//     return dispatch_get_main_queue();
// }

- (void)dealloc {
    [self.pinger stop];
    [self.sendTimer invalidate];
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getIPAddress:(RCTResponseSenderBlock)callback)
{
    NSString *address = @"error";

    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    success = getifaddrs(&interfaces);

    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    callback(@[address]);
}

RCT_EXPORT_METHOD(wake:(NSString *)mac ip:(NSString *)ip callback:(RCTResponseSenderBlock)callback)
{
    NSString *formattedMac = @"error";

	unsigned char *broadcast_addr = (unsigned char*)[ip UTF8String];
    unsigned char *mac_addr = (unsigned char*)[mac UTF8String];

    if (send_wol_packet(broadcast_addr, mac_addr)) {
        formattedMac = @"ok";
    }

    callback(@[formattedMac]);
}

RCT_EXPORT_METHOD(ping:(NSString *)hostName timeout:(nonnull NSNumber *)timeout callback:(RCTResponseSenderBlock)callback)
{
    self.pinger = [[SimplePing alloc] initWithHostName:hostName];
    self.pinger.delegate = self;
    self.callback = callback;
    self.timeout = timeout;

    [self.pinger start];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (self.pinger != nil);
}

- (void)sendPing {
    assert(self.pinger != nil);
    [self.pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);

    NSLog(@"pinging %@", displayAddressForAddress(address));

    // Send the first ping straight away.
    [self sendPing];

    // // And start a timer to send the subsequent pings.
    //
    // assert(self.sendTimer == nil);
    // self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    NSLog(@"failed: %@", shortErrorFromError(error));

    // [self.sendTimer invalidate];
    // self.sendTimer = nil;

    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.

    bool found = false;
    self.callback(@[@(found)]);

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u sent", (unsigned int) sequenceNumber);

    assert(self.sendTimer == nil);
    double tmout = [self.timeout doubleValue] / 1000; // timeout is passed in milliseconds
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:tmout target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u send failed: %@", (unsigned int) sequenceNumber, shortErrorFromError(error));

    bool found = false;
    self.callback(@[@(found)]);

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u received, size=%zu", (unsigned int) sequenceNumber, (size_t) packet.length);

    bool found = true;
    self.callback(@[@(found)]);

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
#pragma unused(pinger)
    assert(pinger == self.pinger);

    NSLog(@"unexpected packet, size=%zu", (size_t) packet.length);

    bool found = false;
    self.callback(@[@(found)]);

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}

- (void)timerFired:(NSTimer *)timer {
    NSLog(@"ping timeout occurred, host not reachable: %d", [self.timeout integerValue]);
    // Move to next host

    bool found = false;
    self.callback(@[@(found)]);

    [self.sendTimer invalidate];
    self.sendTimer = nil;
    self.pinger = nil;
}

RCT_EXPORT_METHOD(poke:(NSString *)hostName port:(nonnull NSString *)port timeout:(nonnull NSNumber *)timeout callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char *host = (char*)[hostName UTF8String];
        int portNum = [port intValue];
        int interval = [timeout intValue];

        bool found = !poke(host, portNum, interval);

        // NSLog(@"poke(%s)-host(%s)-port(%d)", found ? "true" : "false", host, portNum);

        callback(@[@(found)]);
    });
}

@end
  