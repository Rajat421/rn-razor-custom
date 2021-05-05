//
//  RazorpayEventEmitter.m
//  RazorpayCheckout
//
//  Created by Abhinav Arora on 11/10/17.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RazorpayEventEmitter.h"

#import "RCTBridge.h"
#import "RCTEventDispatcher.h"


NSString *const kPaymentError = @"PAYMENT_ERROR";
NSString *const kPaymentSuccess = @"PAYMENT_SUCCESS";
NSString *const kUpiApps = @"UPI_APPS";

@implementation RazorpayEventEmitter

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"Razorpay::PAYMENT_SUCCESS",
        @"Razorpay::PAYMENT_ERROR",
        @"Razorpay::UPI_APPS"
    ];
}

- (void)startObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paymentSuccess:)
                                                 name:kPaymentSuccess
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paymentError:)
                                                 name:kPaymentError
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(upiApps:)
                                                 name:kUpiApps
                                               object:nil];
}

- (void)stopObserving {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)paymentSuccess:(NSNotification *)notification {
    [self sendEventWithName:@"Razorpay::PAYMENT_SUCCESS"
                       body:notification.userInfo];
}

- (void)paymentError:(NSNotification *)notification {
    [self sendEventWithName:@"Razorpay::PAYMENT_ERROR"
                       body:notification.userInfo];
}

- (void)upiApps:(NSNotification *)notification {
    [self sendEventWithName:@"Razorpay::UPI_APPS"
                       body:notification.userInfo];
}

+ (void)onPaymentSuccess:(NSString *)payment_id
                 andData:(NSDictionary *)response {
    NSDictionary *payload = [NSDictionary dictionaryWithDictionary:response];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPaymentSuccess
                                                        object:nil
                                                      userInfo:payload];
}

+ (void)onPaymentError:(int)code
           description:(NSString *)str
               andData:(NSDictionary *)response {
    
    NSMutableDictionary *payload = [response mutableCopy];
    [payload setValue:@(code) forKey:@"code"];
    [payload setValue:str forKey:@"description"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPaymentError
                                                        object:nil
                                                      userInfo:payload];
}

+ (void)upiApps:(NSArray *)upiApps {
    NSMutableArray *apps = [[NSMutableArray alloc] init];
    for (NSString *app in upiApps) {
        NSDictionary *dataDict = @{ @"appName" : app};
        [apps addObject:dataDict];
    }
    NSDictionary *payload = @{ @"data" : apps};
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpiApps
                                                        object:nil
                                                      userInfo:payload];
}


@end
