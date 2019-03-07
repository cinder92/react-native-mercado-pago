//
//  MercadoPagoCheckout+PaymentErrorHandler.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 03/07/2018.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation
extension MercadoPagoCheckout: PXPaymentErrorHandlerProtocol {
    func escError() {
        viewModel.prepareForInvalidPaymentWithESC()
        executeNextStep()
    }

    func identificationError() {
        self.viewModel.paymentData.clearCollectedData()
        let mpInvalidIdentificationError = MPSDKError.init(message: "Algo salió mal...".localized, errorDetail: "El número de identificación es inválido".localized, retry: true)
        self.viewModel.errorInputs(error: mpInvalidIdentificationError, errorCallback: { [weak self] () in
            self?.viewModel.prepareForNewSelection()
            self?.executeNextStep()

        })
        executeNextStep()
    }
}
