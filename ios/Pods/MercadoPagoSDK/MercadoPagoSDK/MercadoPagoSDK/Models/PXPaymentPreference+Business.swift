//
//  PXPaymentPreference+Business.swift
//  MercadoPagoSDKV4
//
//  Created by Eden Torres on 04/09/2018.
//

import Foundation

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l__?, r__?):
        return l__ < r__
    case (nil, _?):
        return true
    default:
        return false
    }
}

private func <= <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l__?, r__?):
        return l__ <= r__
    default:
        return !(rhs < lhs)
    }
}

private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l__?, r__?):
        return l__ > r__
    default:
        return rhs < lhs
    }
}

extension PXPaymentPreference {

    internal func autoSelectPayerCost(_ payerCostList: [PXPayerCost]) -> PXPayerCost? {
        if payerCostList.count == 0 {
            return nil
        }
        if payerCostList.count == 1 {
            return payerCostList.first
        }

        for payercost in payerCostList where payercost.installments == defaultInstallments {
            return payercost
        }

        if (payerCostList.first?.installments <= maxAcceptedInstallments)
            && (payerCostList[1].installments > maxAcceptedInstallments) {
            return payerCostList.first
        } else {
            return nil
        }

    }

    internal func validate() -> Bool {
        if maxAcceptedInstallments <= 0 {
            return false
        }
        if PaymentType.allPaymentIDs.count <= excludedPaymentTypeIds.count {
            return false
        }

        return true
    }

    internal func getExcludedPaymentTypesIds() -> [String] {
            return excludedPaymentTypeIds
    }

    internal func getDefaultInstallments() -> Int {
        if defaultInstallments > 0 {
            return defaultInstallments
        }
        return 0
    }

    internal func getMaxAcceptedInstallments() -> Int {
        if maxAcceptedInstallments > 0 {
            return maxAcceptedInstallments
        }
        return 0
    }

    internal func getExcludedPaymentMethodsIds() -> [String] {
        return excludedPaymentMethodIds
    }

    internal func getDefaultPaymentMethodId() -> String? {
        if defaultPaymentMethodId != nil && defaultPaymentMethodId!.isNotEmpty {
            return defaultPaymentMethodId
        }
        return nil
    }

    internal func addSettings(_ defaultPaymentTypeId: String? = nil, excludedPaymentMethodsIds: [String] = [], excludedPaymentTypesIds: [String] = [], defaultPaymentMethodId: String? = nil, maxAcceptedInstallment: Int = 0, defaultInstallments: Int = 0) -> PXPaymentPreference {

        self.excludedPaymentMethodIds =  excludedPaymentMethodsIds
        self.excludedPaymentTypeIds = excludedPaymentTypesIds
        self.maxAcceptedInstallments = maxAcceptedInstallment
        self.defaultInstallments = defaultInstallments

        if defaultPaymentMethodId != nil {
            self.defaultPaymentMethodId = defaultPaymentMethodId
        }

        if defaultPaymentTypeId != nil {
            self.defaultPaymentTypeId = defaultPaymentTypeId
        }

        return self
    }
}
