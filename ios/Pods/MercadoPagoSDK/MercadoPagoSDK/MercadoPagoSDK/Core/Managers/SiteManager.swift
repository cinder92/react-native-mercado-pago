//
//  SiteHandler.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 16/08/2018.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation

internal class SiteManager {

    // TODO: REMOVE FORCE
    private var siteId: String = ""
    private var termsAndConditionsSite: String = ""
    private var currency: PXCurrency!

    static let shared = SiteManager()

    let siteIdsSettings: [String: NSDictionary] = [
        //Argentina
        "MLA": ["language": "es", "currency": "ARS", "termsconditions": "https://www.mercadopago.com.ar/ayuda/terminos-y-condiciones_299"],
        //Brasil
        "MLB": ["language": "pt", "currency": "BRL", "termsconditions": "https://www.mercadopago.com.br/ajuda/termos-e-condicoes_300"],
        //Chile

        "MLC": ["language": "es", "currency": "CLP", "termsconditions": "https://www.mercadopago.cl/ayuda/terminos-y-condiciones_299"],
        //Mexico
        "MLM": ["language": "es-MX", "currency": "MXN", "termsconditions": "https://www.mercadopago.com.mx/ayuda/terminos-y-condiciones_715"],
        //Peru
        "MPE": ["language": "es", "currency": "PEN", "termsconditions": "https://www.mercadopago.com.pe/ayuda/terminos-condiciones-uso_2483"],
        //Uruguay
        "MLU": ["language": "es", "currency": "UYU", "termsconditions": "https://www.mercadopago.com.uy/ayuda/terminos-y-condiciones-uy_2834"],
        //Colombia
        "MCO": ["language": "es-CO", "currency": "COP", "termsconditions": "https://www.mercadopago.com.co/ayuda/terminos-y-condiciones_299"],
        //Venezuela
        "MLV": ["language": "es", "currency": "VES", "termsconditions": "https://www.mercadopago.com.ve/ayuda/terminos-y-condiciones_299"]
    ]

    func setSite (siteId: String) {
        self.siteId = siteId

        // TODO: Remove force
        let siteConfig = siteIdsSettings[siteId]
        self.currency = CurrenciesUtil.getCurrencyFor(siteConfig!["currency"] as? String)!
        self.termsAndConditionsSite = siteConfig!["termsconditions"] as? String ?? ""
    }

    func getTermsAndConditionsURL() -> String {
        return termsAndConditionsSite
    }

    func getCurrency() -> PXCurrency {
        return currency
    }

    func getSiteId() -> String {
        return siteId
    }
}
