
import { NativeModules } from 'react-native';

const { RNMercadoPago } = NativeModules;

const MercadoPago = {
    startPayment(token,publicKey,items){

        /* send an object { items : [
            {
                "id": "",
                "picture_url": "",
                "title": "Dummy Item",
                "description": "Multicolor Item",
                "category_id": "",
                "currency_id": "MXN",
                "quantity": 1,
                "unit_price": 10
            },
            ...
        ], 
        payer : {
                "name": "",
                "surname": "",
                "email": "payer@email.com",
                "date_created": "",
                "phone": {
                    "area_code": "",
                    "number": ""
                }
            },
        payment_methods": {
                "excluded_payment_methods": [{
                    "id": ""
                }],
                "excluded_payment_types": [{
                    "id": ""
                }],
            } 
        }*/

        //payer email has to be different from the one of credentials.

        return fetch(
            `https://api.mercadopago.com/checkout/preferences?access_token=${token}`,{
                method: 'POST',
                body: JSON.stringify(items),
                headers:{
                    'Content-Type': 'application/json'
                }
            }
        )
        .then(response => response.json())
        .then(preference => {
            if(preference && preference.id){
                RNMercadoPago.startPayment(publicKey,preference.id)
            }
        })


        /*MercadoPago.startPayment("ACCESS_TOKEN","PUBLIC_KEY",data)*/
    }
}

export default MercadoPago;
