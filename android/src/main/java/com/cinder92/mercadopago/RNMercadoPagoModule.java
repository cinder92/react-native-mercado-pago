
package com.cinder92.mercadopago;

import android.app.Activity;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.facebook.react.bridge.WritableMap;
import com.mercadopago.android.px.core.MercadoPagoCheckout;
import com.mercadopago.android.px.internal.util.JsonUtil;
import com.mercadopago.android.px.model.Payment;
import com.mercadopago.android.px.model.PaymentData;
import com.mercadopago.android.px.model.exceptions.MercadoPagoError;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Set;

import static android.app.Activity.RESULT_CANCELED;


public class RNMercadoPagoModule extends ReactContextBaseJavaModule implements ActivityEventListener {

  //private RNMercadoPagoActivity eventResultListener;
  private static final String PAYMENT_CANCELLED = "PAYMENT_CANCELLED";
  private static final String PAYMENT_ERROR = "PAYMENT_ERROR";

  private static final String MP_PAYMENT = "payment";
  private static final String MP_PAYMENT_DATA = "paymentData";
  private static final String MP_PAYMENT_ERROR = "mercadoPagoError";

  private static final String PAYMENT_STATUS = "status";
  private static final String PAYMENT_ID = "id";

  private static final String PAYMENT_DATA_CARD_ISSUER_ID = "cardIssuerId";
  private static final String PAYMENT_DATA_METHOD_ID = "paymentMethodId";
  private static final String PAYMENT_DATA_INSTALLMENT = "installments";
  private static final String PAYMENT_DATA_CAMPAIGN_ID = "campaignId";
  private static final String PAYMENT_DATA_CARD_TOKEN = "cardTokenId";

  private static final int REQUEST_CODE = 1000;
  Promise promise;

  public RNMercadoPagoModule(ReactApplicationContext context) {
    super(context);
    init(context);
  }

  private void init(@NonNull ReactApplicationContext context) {
    //eventResultListener = new RNMercadoPagoActivity();
    context.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "RNMercadoPago";
  }

  public void onNewIntent(Intent intent) { }

  private WritableMap paymentDataToMap(@NonNull PaymentData paymentData) {
    final String paymentMethodId = paymentData.getPaymentMethod().getId();
    final String cardTokenId = paymentData.getToken() == null ? null : paymentData.getToken().getId();
    final String cardIssuerId = paymentData.getIssuer() == null ? null : paymentData.getIssuer().getId().toString();
    final String campaignId = paymentData.getDiscount() == null ? null : paymentData.getDiscount().getId().toString();
    final String installment = paymentData.getPayerCost() == null ? null : paymentData.getPayerCost().getInstallments().toString();

    final WritableMap map = Arguments.createMap();

    map.putString(PAYMENT_DATA_METHOD_ID, paymentMethodId);
    map.putString(PAYMENT_DATA_CARD_TOKEN, cardTokenId);
    map.putString(PAYMENT_DATA_CARD_ISSUER_ID, cardIssuerId);
    map.putString(PAYMENT_DATA_CAMPAIGN_ID, campaignId);
    map.putString(PAYMENT_DATA_INSTALLMENT, installment);

    return map;
  }

  private <T> T getData(@NonNull Intent data, @NonNull String key, @NonNull Class<T> clazz) {
    return JsonUtil.getInstance().fromJson(data.getStringExtra(key), clazz);
  }

  private WritableMap paymentToMap(@NonNull Payment payment) {
    final String paymentId = payment.getId().toString();
    final String paymentStatus = payment.getPaymentStatus();

    final WritableMap map = Arguments.createMap();

    map.putString(PAYMENT_ID, paymentId);
    map.putString(PAYMENT_STATUS, paymentStatus);

    return map;
  }

  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {

    JSONObject json = new JSONObject();
    Set<String> keys = data.getExtras().keySet();

    for (String key : keys) {
      try {
        // json.put(key, bundle.get(key)); see edit below
        json.put(key, JSONObject.wrap(data.getExtras().get(key)));
      } catch(JSONException e) {
        //Handle exception here
      }
    }

      Log.d("pago con Activity => ", json.toString() );

      if (promise == null || requestCode != REQUEST_CODE || data == null) {
      return;
    }

    if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
        if(data != null && data.getStringExtra(MP_PAYMENT_DATA) != null) {
          final PaymentData paymentData = this.getData(data, MP_PAYMENT_DATA, PaymentData.class);
          final WritableMap paymentDataMap = this.paymentDataToMap(paymentData);

          //Resolve values as map
          promise.resolve(paymentDataMap);
        }
    }
    else if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
        if(data != null && data.getStringExtra(MP_PAYMENT) != null) {
          final Payment payment = this.getData(data, MP_PAYMENT, Payment.class);
          final WritableMap paymentMap = this.paymentToMap(payment);

          //Resolve values as map
          promise.resolve(paymentMap);
        }
    }
    else if (resultCode == RESULT_CANCELED) {
      if (data != null && data.getStringExtra(MP_PAYMENT_ERROR) != null) {
        final MercadoPagoError mercadoPagoError = this.getData(data, MP_PAYMENT_ERROR, MercadoPagoError.class);
        final Throwable wrappedError = new Throwable(mercadoPagoError.getErrorDetail());

        //Reject promise on MPError, and bubble error data to react-native
        promise.reject(PAYMENT_ERROR, "Payment failed.", wrappedError);
      }
      else {
        //Reject promise on user cancellation
        promise.reject(PAYMENT_CANCELLED, "Payment was cancelled by the user.");
      }
    }

    promise = null;
    //this.clearCurrentPromise();
  }

  public void onActivityResult(int requestCode, int resultCode, Intent data) {
      Log.d("pago sin activity => ",Integer.toString(requestCode) + " - " + Integer.toString(resultCode) + " => " + MercadoPagoCheckout.EXTRA_PAYMENT_RESULT);

      if (promise == null || requestCode != REQUEST_CODE) {
      return;
    }

    if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
      final PaymentData paymentData = this.getData(data, MP_PAYMENT_DATA, PaymentData.class);
      final WritableMap paymentDataMap = this.paymentDataToMap(paymentData);

      //Resolve values as map
      promise.resolve(paymentDataMap);
    }
    else if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
      final Payment payment = this.getData(data, MP_PAYMENT, Payment.class);
      final WritableMap paymentMap = this.paymentToMap(payment);

      //Resolve values as map
      promise.resolve(paymentMap);
    }
    else if (resultCode == RESULT_CANCELED) {
      if (data != null && data.getStringExtra(MP_PAYMENT_ERROR) != null) {
        final MercadoPagoError mercadoPagoError = this.getData(data, MP_PAYMENT_ERROR, MercadoPagoError.class);
        final Throwable wrappedError = new Throwable(mercadoPagoError.getErrorDetail());

        //Reject promise on MPError, and bubble error data to react-native
        promise.reject(PAYMENT_ERROR, "Payment failed.", wrappedError);
      }
      else {
        //Reject promise on user cancellation
        promise.reject(PAYMENT_CANCELLED, "Payment was cancelled by the user.");
      }
    }

    promise = null;
    //this.clearCurrentPromise();
  }

  private void setCurrentPromise(@NonNull Promise promise) {
    this.promise = promise;
    //eventResultListener.setCurrentPromise(promise);
  }

  @ReactMethod
  public void startPayment(@NonNull String publicKey, @NonNull String preferenceId, @NonNull Promise promise){
      this.setCurrentPromise(promise);
      Activity currentActivity = this.getCurrentActivity();

      new MercadoPagoCheckout.Builder(publicKey, preferenceId)
              .build()
              .startPayment(currentActivity, REQUEST_CODE);
  }
}