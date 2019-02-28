
package com.cinder92.mercadopago;

import android.icu.math.BigDecimal;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

/*import com.mercadopago.android.px.core.MercadoPagoCheckout.Builder;
import com.mercadopago.*;
import com.mercadopago.exceptions.MPConfException;
import com.mercadopago.exceptions.MPException;
import com.mercadopago.resources.Payment;
import com.mercadopago.resources.datastructures.payment.Payer;*/
import com.mercadopago.android.px.configuration.AdvancedConfiguration;
import com.mercadopago.android.px.core.MercadoPagoCheckout;
import com.mercadopago.android.px.model.PaymentMethods;
import com.mercadopago.android.px.model.PaymentTypes;
import com.mercadopago.android.px.model.Sites;
import com.mercadopago.android.px.preferences.CheckoutPreference;

public class RNMercadoPagoModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private static final int REQUEST_CODE = 1000;

  public RNMercadoPagoModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNMercadoPago";
  }

  //receive callbacks
  /*protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == MercadoPagoCheckout.) {
            if (resultCode == MercadoPagoCheckout.PAYMENT_RESULT_CODE) {
                Payment payment = JsonUtil.getInstance().fromJson(data.getStringExtra("payment"), Payment.class);
                //Done!
            } else if (resultCode == RESULT_CANCELED) {
                if (data != null && data.getStringExtra("mercadoPagoError") != null) {
                    //Resolve error in checkout
                } else {
                    //Resolve canceled checkout
                }
            }
        }
  }*/

  @ReactMethod
  public void startPayment(String publicKey, String preferenceId){
    new MercadoPagoCheckout.Builder(publicKey, preferenceId)
              .build()
              .startPayment(reactContext, REQUEST_CODE);

  }
}