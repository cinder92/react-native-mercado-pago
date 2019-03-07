//
//  RNMercadoPago.swift
//  RNMercadoPago
//
//  Created by Dante Cervantes on 3/1/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import MercadoPagoSDK

@objc(MercadoPago)
class MercadoPago: NSObject {
    
    @objc
    func getCount(_ publicKey : NSString, _ preferenceId : NSString,  _ callback: RCTResponseSenderBlock) {
        //callback([count])
        
        let checkout = MercadoPagoCheckout.init(builder: MercadoPagoCheckoutBuilder.init(publicKey: publicKey, preferenceId: preferenceId))
        
        checkout.start(navigationController: self.navigationController!)
        
    }
    
}

