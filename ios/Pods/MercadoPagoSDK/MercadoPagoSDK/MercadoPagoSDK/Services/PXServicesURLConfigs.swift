//
//  PXServicesURLConfigs.swift
//  MercadoPagoServices
//
//  Created by Eden Torres on 11/8/17.
//  Copyright © 2017 Mercado Pago. All rights reserved.
//

import Foundation

internal class PXServicesURLConfigs: NSObject {
    static var MP_TEST_ENV = "/beta"
    static var MP_PROD_ENV = "/v1"
    static var MP_SELECTED_ENV = MP_PROD_ENV
    static var PX_SDK_VERSION: String?
    static var API_VERSION = "1.6"
    static let MP_API_BASE_URL_PROD: String =  "https://api.mercadopago.com"
    static let MP_API_BASE_URL: String =  MP_API_BASE_URL_PROD

    static var MP_ENVIROMENT = MP_SELECTED_ENV  + "/checkout"
    static let MP_OP_ENVIROMENT = "/v1"
    static let PAYMENT_METHODS = "/payment_methods"
    static let INSTALLMENTS = "\(PAYMENT_METHODS)/installments"
    static let CARD_TOKEN = "/card_tokens"
    static let CARD_ISSSUERS = "\(PAYMENT_METHODS)/card_issuers"
    static let PAYMENTS = "/payments"
    static let MP_CREATE_TOKEN_URI = MP_OP_ENVIROMENT + CARD_TOKEN
    static let MP_PAYMENT_METHODS_URI = MP_OP_ENVIROMENT + PAYMENT_METHODS
    static var MP_INSTALLMENTS_URI = MP_ENVIROMENT + INSTALLMENTS
    static var MP_ISSUERS_URI = MP_ENVIROMENT + CARD_ISSSUERS
    static let MP_IDENTIFICATION_URI = "/identification_types"
    static let MP_PROMOS_URI = MP_OP_ENVIROMENT + PAYMENT_METHODS + "/deals"
    static let MP_SEARCH_PAYMENTS_URI = "\(MP_SELECTED_ENV)/px_mobile_api/payment_methods"
    static let MP_INSTRUCTIONS_URI = MP_ENVIROMENT + PAYMENTS + "/${payment_id}/results"
    static let MP_PREFERENCE_URI = MP_ENVIROMENT + "/preferences/"
    static let MP_DISCOUNT_URI =  "/discount_campaigns/"
    static let MP_CUSTOMER_URI = "/customers?preference_id="
    static let MP_CAMPAIGNS_URI = "/campaigns/check_availability"
}
