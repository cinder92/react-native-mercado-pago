
package com.cinder92.mercadopago;

import android.app.Activity;
import android.content.Intent;
import android.support.annotation.NonNull;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.facebook.react.bridge.WritableMap;
import com.mercadopago.android.px.core.MercadoPagoCheckout;
import com.mercadopago.android.px.model.Payment;
import com.mercadopago.android.px.model.exceptions.MercadoPagoError;

import static android.app.Activity.RESULT_CANCELED;


public class RNMercadoPagoModule extends ReactContextBaseJavaModule implements ActivityEventListener {

  private static final int REQUEST_CODE = 1000;
  Promise promise;

  public RNMercadoPagoModule(ReactApplicationContext context) {
    super(context);
    init(context);
  }

  private void init(@NonNull ReactApplicationContext context) {
    context.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "RNMercadoPago";
  }

  public void onNewIntent(Intent intent) { }

  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
    this.onActivityResult(requestCode, resultCode, data);
  }

  public void onActivityResult(final int requestCode, final int resultCode, final Intent data) {

    if (requestCode == REQUEST_CODE) {
      if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
          final Payment payment = (Payment) data.getSerializableExtra(MercadoPagoCheckout.EXTRA_PAYMENT_RESULT);

          WritableMap map = Arguments.createMap();

          map.putBoolean("response",true);
          map.putString("status",payment.getPaymentStatus());
          map.putString("detail",payment.getPaymentStatusDetail());
          map.putString("desc",payment.getDescription());

          promise.resolve(map);

      } else if (resultCode == RESULT_CANCELED) {
          if (data != null && data.getExtras() != null
              && data.getExtras().containsKey(MercadoPagoCheckout.EXTRA_ERROR)) {
              final MercadoPagoError mercadoPagoError =
                  (MercadoPagoError) data.getSerializableExtra(MercadoPagoCheckout.EXTRA_ERROR);

              WritableMap map = Arguments.createMap();

              map.putBoolean("response",false);
              map.putString("message",mercadoPagoError.getMessage());

              promise.resolve(map);

          } else {
            WritableMap map = Arguments.createMap();

            map.putBoolean("response",false);
            map.putString("message","payment canceled by user");

            promise.resolve(map);
          }
      }
    }
  }

  private void setCurrentPromise(@NonNull Promise promise) {
    this.promise = promise;
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