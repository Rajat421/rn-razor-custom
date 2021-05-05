//
//  RazorpayCheckout.m
//  RazorpayCheckout
//
//  Created by Abhinav Arora on 11/10/17.
//  Copyright © 2016 Razorpay. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "RazorpayCustomui.h"
#import "RazorpayEventEmitter.h"

#import <Razorpay/Razorpay-Swift.h>

@interface RazorpayCustomui () <RazorpayPaymentCompletionProtocol, WKNavigationDelegate, WKUIDelegate>{
    RazorpayCheckout *razorpay;
    UIViewController *parentVC;
    WKWebView *webview;
    UINavigationController *navController;
    UIBarButtonItem *cancelBtn;
    UIWindow *window;
}
@end

@implementation RazorpayCustomui

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getAppsWhichSupportUpi) {
    [RazorpayCheckout getAppsWhichSupportUpiWithHandler:^(NSArray<NSString *> * supportedApps) {
        [RazorpayEventEmitter upiApps:supportedApps];
    }];
}

RCT_EXPORT_METHOD(open : (NSDictionary *)options) {

    NSString *keyID = (NSString *)[options objectForKey:@"key_id"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRotation) name:UIDeviceOrientationDidChangeNotification object:nil];

    dispatch_sync(dispatch_get_main_queue(), ^{

        cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onTapCancel:)];
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        //Setting web view
        webview = [[WKWebView alloc] initWithFrame: parentVC.view.frame configuration:configuration];
        webview.navigationDelegate = self;
        webview.UIDelegate = self;
        webview.opaque = YES;
        webview.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];

        [self resizeView];

        //setting parent view controller
        parentVC = [UIViewController new];
        [parentVC.view addSubview:webview];

        if ([[parentVC navigationController] navigationBar] != nil) {
            navController = parentVC.navigationController;
        } else {
            navController = [[UINavigationController alloc] initWithRootViewController:parentVC];
        }

        parentVC.title = @"Authorize Payment";
        parentVC.navigationItem.leftBarButtonItem = cancelBtn;


        parentVC.view.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight |
         UIViewAutoresizingFlexibleWidth);

        webview.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight |
         UIViewAutoresizingFlexibleWidth);

        window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        window.windowLevel = UIWindowLevelStatusBar;
        window.backgroundColor = [UIColor clearColor];
        [window makeKeyAndVisible];
        [window setRootViewController:navController];

        razorpay = [RazorpayCheckout initWithKey:keyID andDelegate:self withPaymentWebView:webview];

        NSMutableDictionary * tempOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
        [razorpay authorize:tempOptions];
    });
}


-(void)onTapCancel: (id) sender{
    [razorpay userCancelledPayment];
    [RazorpayEventEmitter onPaymentError:1 description:@"User Cancelled Payment" andData:[NSMutableDictionary dictionary]];
    [razorpay close];
    [self close];
}

- (void)onPaymentSuccess:(nonnull NSString *)payment_id
                 andData:(NSDictionary *)response {
    if (response == nil){
        [RazorpayEventEmitter onPaymentSuccess:payment_id andData:[NSMutableDictionary dictionary]];
    }else{
        [RazorpayEventEmitter onPaymentSuccess:payment_id andData:response];
    }
    [razorpay close];
    [self close];
}

- (void)onPaymentError:(int)code
           description:(nonnull NSString *)str
               andData:(NSDictionary *)response {
    if (response == nil){
        [RazorpayEventEmitter onPaymentError:code description:str andData:[NSMutableDictionary dictionary]];
    }else{
        [RazorpayEventEmitter onPaymentError:code description:str andData:response];
    }

    [razorpay close];
    [self close];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [razorpay webView:webview didFail:navigation withError:error];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [razorpay webView:webview didFinish:navigation];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [razorpay webView:webview didCommit:navigation];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [razorpay webView:webview didFailProvisionalNavigation:navigation withError:error];
}

- (void)handleRotation {
    [self resizeView];
}

- (void)resizeView{
    CGFloat paddingTop = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat statusHeight = 44;
    [webview setFrame:CGRectMake(0, statusHeight + paddingTop, size.width,
                                 size.height - statusHeight - paddingTop)];
}

- (void)close{


    if (webview != nil){
        [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        webview.backgroundColor = [UIColor clearColor];
        [webview stopLoading];
    }

    if (navController != nil){
        [navController dismissViewControllerAnimated:true completion:nil];
    }

    razorpay = nil;

    webview = nil;

    parentVC.view = nil;
    parentVC = nil;

    cancelBtn = nil;

    window.hidden = YES;
    window = nil;

}

@end

