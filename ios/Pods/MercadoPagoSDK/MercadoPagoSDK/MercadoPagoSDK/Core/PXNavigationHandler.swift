//
//  PXNavigationHandler.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 03/05/2018.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation

internal class PXNavigationHandler: NSObject {

    var countLoadings: Int = 0
    var navigationController: UINavigationController!
    var viewControllerBase: UIViewController?
    private var currentLoadingView: UIViewController?
    private var rootViewController: UIViewController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        if self.navigationController.viewControllers.count > 0 {
            let newNavigationStack = self.navigationController.viewControllers.filter {!$0.isKind(of: MercadoPagoUIViewController.self) || $0.isKind(of: PXReviewViewController.self)
            }
            viewControllerBase = newNavigationStack.last
        }
    }

    func goToRootViewController() {
        guard let rootViewController = viewControllerBase else {
            navigationController.popToRootViewController(animated: true)
            navigationController.setNavigationBarHidden(false, animated: false)
            return
        }
        if navigationController.viewControllers.contains(rootViewController) {
            navigationController.popToViewController(rootViewController, animated: true)
        } else {
            navigationController.popToRootViewController(animated: true)
        }
        navigationController.setNavigationBarHidden(false, animated: false)
    }

    func presentLoading(animated: Bool = false, completion: (() -> Swift.Void)? = nil) {
        self.countLoadings += 1
        if self.countLoadings == 1 {
            let when = DispatchTime.now() //+ 0.3
            DispatchQueue.main.asyncAfter(deadline: when) {
                if self.countLoadings > 0 && self.currentLoadingView == nil {
                    self.createCurrentLoading()
                    self.currentLoadingView?.modalTransitionStyle = .crossDissolve
                    self.navigationController.present(self.currentLoadingView!, animated: true, completion: completion)
                }
            }
        }
    }

    func presentInitLoading() {
        self.createCurrentLoading()
        self.currentLoadingView?.modalTransitionStyle = .crossDissolve
        self.navigationController.present(self.currentLoadingView!, animated: false, completion: nil)
    }

    func dismissLoading(animated: Bool = true, finishCallback:(() -> Void)? = nil) {
        self.countLoadings = 0
        if self.currentLoadingView != nil {
            self.currentLoadingView?.modalTransitionStyle = .crossDissolve
            self.currentLoadingView!.dismiss(animated: animated, completion: {
                self.currentLoadingView = nil
                if let callback = finishCallback {
                    callback()
                }
            })
        }
    }

    func isLoadingPresented() -> Bool {
        return self.currentLoadingView != nil
    }

    internal func createCurrentLoading() {
        self.currentLoadingView = PXLoadingViewController()
    }

    internal func showErrorScreen(error: MPSDKError?, callbackCancel: (() -> Void)?, errorCallback: (() -> Void)?) {
        let errorVC = ErrorViewController(error: error, callback: nil, callbackCancel: callbackCancel)
        errorVC.callback = {
            self.navigationController.dismiss(animated: true, completion: {
                errorCallback?()
            })
        }
        if isLoadingPresented() {
            dismissLoading {  [weak self] in
                self?.navigationController.present(errorVC, animated: true, completion: {})
            }
        } else {
            self.navigationController.present(errorVC, animated: true, completion: {})
        }
    }

    internal func pushViewController(viewController: MercadoPagoUIViewController,
                                     animated: Bool, backToFirstPaymentVault: Bool = false) {
        viewController.hidesBottomBarWhenPushed = true

        // TODO: Review with Product, navigation flow for -> backToFirstPaymentVault = true.
        if backToFirstPaymentVault {
            self.navigationController.navigationBar.isHidden = false
            viewController.callbackCancel = { [weak self] in self?.backToFirstPaymentVaultViewController() }
        }

        self.navigationController.pushViewController(viewController, animated: animated)
        self.cleanCompletedCheckoutsFromNavigationStack()
        self.dismissLoading()
    }

    internal func pushViewController(targetVC: UIViewController,
                                     animated: Bool) {

        targetVC.hidesBottomBarWhenPushed = true
        self.navigationController.pushViewController(targetVC, animated: animated)
        self.cleanCompletedCheckoutsFromNavigationStack()
        self.dismissLoading()
    }

    func popViewController(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    func backToFirstPaymentVaultViewController() {
        let mercadoPagoPaymentVaultViewController = self.navigationController.viewControllers.filter {$0.isKind(of: MercadoPagoUIViewController.self) && $0.isKind(of: PaymentVaultViewController.self)}
        if !mercadoPagoPaymentVaultViewController.isEmpty {
            self.navigationController.popToViewController(mercadoPagoPaymentVaultViewController[0], animated: true)
        } else {
            navigationController.popViewController(animated: true)
        }
    }

    internal func removeRootLoading() {
        let currentViewControllers = self.navigationController.viewControllers.filter { (viewController: UIViewController) -> Bool in
            return viewController != self.rootViewController
        }
        self.navigationController.viewControllers = currentViewControllers
    }

    func cleanCompletedCheckoutsFromNavigationStack() {
        let  pxResultViewControllers = self.navigationController.viewControllers.filter {$0.isKind(of: PXResultViewController.self)}
        if let lastResultViewController = pxResultViewControllers.last {
            let index = self.navigationController.viewControllers.index(of: lastResultViewController)
            let  validViewControllers = self.navigationController.viewControllers.filter {!$0.isKind(of: MercadoPagoUIViewController.self) || self.navigationController.viewControllers.index(of: $0)! > index! || $0 == self.navigationController.viewControllers.last }
            self.navigationController.viewControllers = validViewControllers
        }
    }
}

internal extension PXNavigationHandler {
    static func getDefault() -> PXNavigationHandler {
        return PXNavigationHandler.init(navigationController: UINavigationController())
    }
}

/** :nodoc: */
extension PXNavigationHandler: UINavigationControllerDelegate {
    func suscribeToNavigationFlow() {
        navigationController.delegate = self
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if !(viewController is MercadoPagoUIViewController) {
            if (viewController is PXPaymentProcessor) || (viewController is PXPaymentMethodConfigProtocol) {
                return
            }
            PXCheckoutStore.sharedInstance.clean()
        }
    }
}
