//
//  RazorpayEventEmitter.h
//  RazorpayCheckout
//
//  Created by Abhinav Arora on 11/10/17.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTEventEmitter.h"

@interface RazorpayEventEmitter : RCTEventEmitter

+ (void)onPaymentSuccess:(NSString *)payment_id
                 andData:(NSDictionary *)response;
+ (void)onPaymentError:(int)code
           description:(NSString *)str
               andData:(NSDictionary *)response;
+ (void)upiApps:(NSArray *)upiApps;

@end
