'use strict';

import { NativeModules, NativeEventEmitter } from 'react-native';

const razorpayEvents = new NativeEventEmitter(NativeModules.RazorpayEventEmitter);

const removeSubscriptions = () => {
  razorpayEvents.removeAllListeners('Razorpay::PAYMENT_SUCCESS');
  razorpayEvents.removeAllListeners('Razorpay::PAYMENT_ERROR');
  razorpayEvents.removeAllListeners('Razorpay::UPI_APPS');
};

class Razorpay {
  static open(options, successCallback, errorCallback) {
    return new Promise(function(resolve, reject) {
      razorpayEvents.addListener('Razorpay::PAYMENT_SUCCESS', (data) => {
        let resolveFn = successCallback || resolve;
        resolveFn(data);
        removeSubscriptions();
      });
      razorpayEvents.addListener('Razorpay::PAYMENT_ERROR', (data) => {
        let rejectFn = errorCallback || reject;
        rejectFn(data);
        removeSubscriptions();
      });
      NativeModules.RazorpayCustomui.open(options);
    });
  }
  static getAppsWhichSupportUPI(upiAppCallback){
    return new Promise(function(resolve,reject){
      razorpayEvents.addListener('Razorpay::UPI_APPS',(data)=>{
        let resolveFn = upiAppCallback || resolve;
        resolveFn(data);
        removeSubscriptions
      });
      NativeModules.RazorpayCustomui.getAppsWhichSupportUpi();
    });
  }
}

export default Razorpay;
