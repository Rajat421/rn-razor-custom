
package com.razorpay.rn;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.razorpay.PaymentData;
import com.razorpay.PaymentResultWithDataListener;
import org.json.JSONArray;
import org.json.JSONException;
import com.razorpay.Razorpay;
import com.razorpay.RzpUpiSupportedAppsCallback;
import org.json.JSONObject;
import java.util.Iterator;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import java.util.ArrayList;
import java.util.List;
import com.razorpay.ApplicationDetails;




public class RazorpayModule extends ReactContextBaseJavaModule implements ActivityEventListener, RzpUpiSupportedAppsCallback  {


  public static final int RZP_REQUEST_CODE = 72967729;
  public static final String MAP_KEY_RZP_PAYMENT_ID = "razorpay_payment_id";
  public static final String MAP_KEY_PAYMENT_ID = "payment_id";
  public static final String MAP_KEY_ERROR_CODE = "code";
  public static final String MAP_KEY_ERROR_DESC = "description";
  public static final String MAP_KEY_PAYMENT_DETAILS = "details";
  public static final String MAP_KEY_WALLET_NAME="name";
  ReactApplicationContext reactContext;
  public RazorpayModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "RazorpayCustomui";
  }

  @ReactMethod
  public void open(ReadableMap options) {
    Activity currentActivity = getCurrentActivity();
    try {
      JSONObject optionsJSON = Utils.readableMapToJson(options);
      Intent intent = new Intent(currentActivity, RazorpayPaymentActivity.class);
      intent.putExtra(Constants.OPTIONS, optionsJSON.toString());
      currentActivity.startActivityForResult(intent, RazorpayPaymentActivity.RZP_REQUEST_CODE);
    } catch (Exception e) {}
  }

  @ReactMethod
  public void getAppsWhichSupportUpi(){
    Activity currentActivity = getCurrentActivity();
    Razorpay.getAppsWhichSupportUpi(currentActivity, this);
  }


  @Override
  public void onReceiveUpiSupportedApps(List applicationDetailsList){
    List<ApplicationDetails> data = applicationDetailsList;
    JSONObject returnData = new JSONObject();
    JSONArray jsonArray = new JSONArray();
    try{

    for(int i=0;i<applicationDetailsList.size();i++){
        JSONObject app = new JSONObject();
        app.put("appName",data.get(i).getAppName());
        app.put("packageName",data.get(i).getPackageName());
        app.put("iconBase64",data.get(i).getIconBase64());
        jsonArray.put(app);
        
      
    }
      returnData.put("data",jsonArray);
    }catch(JSONException e){
      e.printStackTrace();
    }
    sendEvent("Razorpay::UPI_APPS",Utils.jsonToWritableMap(returnData));
    
  }
 
  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
    if(requestCode == RazorpayPaymentActivity.RZP_REQUEST_CODE && resultCode == RazorpayPaymentActivity.RZP_RESULT_CODE){
      onActivityResult(requestCode, resultCode, data);
    }
  }

  public void onNewIntent(Intent intent) {}


  public void onActivityResult(int requestCode, int resultCode, Intent data){
    String paymentDataString = data.getStringExtra(Constants.PAYMENT_DATA);
    JSONObject paymentData = new JSONObject();
    try{
          paymentData = new JSONObject(paymentDataString);
    } catch(Exception e){
    }
     if(data.getBooleanExtra(Constants.IS_SUCCESS, false)){
      String payment_id = data.getStringExtra(Constants.PAYMENT_ID);
      onPaymentSuccess(payment_id, paymentData);
     } else {
      int errorCode = data.getIntExtra(Constants.ERROR_CODE, 0);
      String errorMessage = data.getStringExtra(Constants.ERROR_MESSAGE);
      onPaymentError(errorCode, errorMessage, paymentData);
     }
  }

  private void sendEvent(String eventName, WritableMap params) {
  reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(eventName, params);
  }

   
    public void onPaymentSuccess(String razorpayPaymentId, JSONObject paymentData) {
      sendEvent("Razorpay::PAYMENT_SUCCESS", Utils.jsonToWritableMap(paymentData)); 
    }

    
    public void onPaymentError(int code, String description, JSONObject paymentDataJson) {
      WritableMap errorParams = Arguments.createMap();
      try{
        paymentDataJson.put(MAP_KEY_ERROR_CODE, code);
        paymentDataJson.put(MAP_KEY_ERROR_DESC, description);
      } catch(Exception e){
      }
      sendEvent("Razorpay::PAYMENT_ERROR", Utils.jsonToWritableMap(paymentDataJson));
    }
}
