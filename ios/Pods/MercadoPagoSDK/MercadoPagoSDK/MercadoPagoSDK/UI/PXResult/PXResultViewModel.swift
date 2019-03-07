//
//  PXResultViewModel.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 20/10/17.
//  Copyright © 2017 MercadoPago. All rights reserved.
//

import UIKit

internal class PXResultViewModel: PXResultViewModelInterface {
    var screenName: String { return TrackingUtil.SCREEN_NAME_PAYMENT_RESULT }
    var screenId: String { return TrackingUtil.SCREEN_ID_PAYMENT_RESULT }

    var paymentResult: PaymentResult
    var instructionsInfo: PXInstructions?
    var preference: PXPaymentResultConfiguration
    var callback: ((PaymentResult.CongratsState) -> Void)!
    let amountHelper: PXAmountHelper

    let warningStatusDetails = [PXRejectedStatusDetail.INVALID_ESC, PXRejectedStatusDetail.CALL_FOR_AUTH, PXRejectedStatusDetail.BAD_FILLED_CARD_NUMBER, PXRejectedStatusDetail.CARD_DISABLE, PXRejectedStatusDetail.INSUFFICIENT_AMOUNT, PXRejectedStatusDetail.BAD_FILLED_DATE, PXRejectedStatusDetail.BAD_FILLED_SECURITY_CODE, PXRejectedStatusDetail.BAD_FILLED_OTHER]

    init(amountHelper: PXAmountHelper, paymentResult: PaymentResult, instructionsInfo: PXInstructions? = nil, resultConfiguration: PXPaymentResultConfiguration = PXPaymentResultConfiguration()) {
        self.paymentResult = paymentResult
        self.instructionsInfo = instructionsInfo
        self.preference =  resultConfiguration
        self.amountHelper = amountHelper
    }

    func trackInfo() {
        var metadata = [TrackingUtil.METADATA_PAYMENT_IS_EXPRESS: TrackingUtil.IS_EXPRESS_DEFAULT_VALUE,
                        TrackingUtil.METADATA_PAYMENT_STATUS: self.getPaymentStatus(),
                        TrackingUtil.METADATA_PAYMENT_STATUS_DETAIL: self.getPaymentStatusDetail(),
                        TrackingUtil.METADATA_PAYMENT_ID: self.getPaymentId() ?? ""]
        if let pm = self.getPaymentData().getPaymentMethod() {
            metadata[TrackingUtil.METADATA_PAYMENT_METHOD_ID] = pm.id
        }
        if let issuer = self.getPaymentData().getIssuer() {
            metadata[TrackingUtil.METADATA_ISSUER_ID] = issuer.id
        }

        let finalId = "\(screenId)/\(self.getPaymentStatus())"

        var name = screenName
        if self.isCallForAuth() {
            name = TrackingUtil.SCREEN_NAME_PAYMENT_RESULT_CALL_FOR_AUTH
        }

        MPXTracker.sharedInstance.trackScreen(screenId: finalId, screenName: name, properties: metadata)
    }

    func getPaymentData() -> PXPaymentData {
        return self.paymentResult.paymentData!
    }

    func setCallback(callback: @escaping ((PaymentResult.CongratsState) -> Void)) {
        self.callback = callback
    }

    func getPaymentStatus() -> String {
        return self.paymentResult.status
    }

    func getPaymentStatusDetail() -> String {
        return self.paymentResult.statusDetail
    }

    func getPaymentId() -> String? {
        return self.paymentResult.paymentId
    }
    func isCallForAuth() -> Bool {
        return self.paymentResult.isCallForAuth()
    }

    func primaryResultColor() -> UIColor {
        return ResourceManager.shared.getResultColorWith(status: paymentResult.status, statusDetail: paymentResult.statusDetail)
    }
}
