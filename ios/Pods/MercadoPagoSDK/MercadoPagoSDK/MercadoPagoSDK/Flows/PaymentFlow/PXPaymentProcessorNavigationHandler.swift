//
//  PXPaymentProcessorNavigationHandler.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 17/07/2018.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation

/**
 Navigation handler to manage communication between your Processor and our Checkout. You should use this navigation handler only with custom Processor view. When you use a custom `UIViewController` to present youur own view, you can use this Object in order to notify: `didFinishPayment`, `showLoading`, `hideLoading`.
 */
@objcMembers
open class PXPaymentProcessorNavigationHandler: NSObject {
    private var flow: PXPaymentFlow?

    internal init(flow: PXPaymentFlow) {
        self.flow = flow
    }

    // MARK: Notify your payment.
    /**
     Notify that your custom payment was finish. Send your custom `PXBusinessResult` object.
     - parameter businessResult: Your custom `PXBusinessResult`.
     */
    open func didFinishPayment(businessResult: PXBusinessResult) {
        self.flow?.model.businessResult = businessResult
        self.flow?.executeNextStep()
    }

    /// :nodoc:
    open func didFinishPayment(paymentStatus: PXGenericPayment.RemotePaymentStatus, statusDetails: String = "", paymentId: String? = nil) {

        guard let paymentData = self.flow?.model.paymentData else {
            return
        }

        if statusDetails == PXRejectedStatusDetail.INVALID_ESC.rawValue {
            flow?.paymentErrorHandler?.escError()
            return
        }

        var statusDetailsStr = statusDetails

        // By definition of MVP1, we support only approved or rejected.
        var paymentStatusStrDefault = PXPaymentStatus.REJECTED.rawValue
        if paymentStatus == .APPROVED {
            paymentStatusStrDefault = PXPaymentStatus.APPROVED.rawValue
        }

        // Set paymentPlugin image into payment method.
        if self.flow?.model.paymentData?.paymentMethod?.paymentTypeId == PXPaymentTypes.PAYMENT_METHOD_PLUGIN.rawValue {

            // Defaults status details for paymentMethod plugin
            if paymentStatus == .APPROVED {
                statusDetailsStr = ""
            } else {
                statusDetailsStr = PXRejectedStatusDetail.REJECTED_PLUGIN_PM.rawValue
            }
        }

        let paymentResult = PaymentResult(status: paymentStatusStrDefault, statusDetail: statusDetailsStr, paymentData: paymentData, payerEmail: nil, paymentId: paymentId, statementDescription: nil)

        flow?.model.paymentResult = paymentResult
        flow?.executeNextStep()
    }

    /**
     Notify that your payment was finish. Send a default Payment.
     - parameter status: Status of your payment.
     - parameter statusDetail: Status detail of your payment.
     - parameter paymentId: Id of your payment.
     */
    open func didFinishPayment(status: String, statusDetail: String, paymentId: String? = nil) {

        guard let paymentData = self.flow?.model.paymentData else {
            return
        }

        if statusDetail == PXRejectedStatusDetail.INVALID_ESC.rawValue {
            flow?.paymentErrorHandler?.escError()
            return
        }

        let paymentResult = PaymentResult(status: status, statusDetail: statusDetail, paymentData: paymentData, payerEmail: nil, paymentId: paymentId, statementDescription: nil)

        flow?.model.paymentResult = paymentResult
        flow?.executeNextStep()
    }

    // MARK: Navigation actions.

    /**
     Call to Checkout next screen.
     */
    open func next() {
        flow?.executeNextStep()
    }

    /**
     Call to Checkout next screen and remove current screen from stack.
     */
    open func nextAndRemoveCurrentScreenFromStack() {
        guard let currentViewController = self.flow?.pxNavigationHandler.navigationController.viewControllers.last else {
            flow?.executeNextStep()
            return
        }

        flow?.executeNextStep()

        if let indexOfLastViewController = self.flow?.pxNavigationHandler.navigationController.viewControllers.index(of: currentViewController) {
            self.flow?.pxNavigationHandler.navigationController.viewControllers.remove(at: indexOfLastViewController)
        }
    }

    /**
     Show our Checkout loading full screen.
     */
    open func showLoading() {
        flow?.pxNavigationHandler.presentLoading()
    }

    /**
     Hide our Checkout loading full screen.
     */
    open func hideLoading() {
        flow?.pxNavigationHandler.dismissLoading()
    }
}
