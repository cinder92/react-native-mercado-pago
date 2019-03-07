//
//  PXContainedActionButtonRenderer.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 23/1/18.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import UIKit

class PXContainedActionButtonRenderer: NSObject {

    let BUTTON_HEIGHT: CGFloat = 50

    func render(_ containedButton: PXContainedActionButtonComponent) -> PXContainedActionButtonView {

        let containedButtonView =  PXContainedActionButtonView()

        containedButtonView.translatesAutoresizingMaskIntoConstraints = false

        let button = self.buildButton(with: containedButton.props.action, title: containedButton.props.title)
        containedButtonView.button = button
        containedButtonView.button?.animationDelegate = containedButton.props.animationDelegate
        containedButtonView.addSubview(button)

        containedButtonView.backgroundColor = .white
        containedButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        containedButtonView.layer.shadowColor = UIColor.black.cgColor
        containedButtonView.layer.shadowRadius = 4
        containedButtonView.layer.shadowOpacity = 0.25

        PXLayout.pinTop(view: button, to: containedButtonView, withMargin: PXLayout.S_MARGIN).isActive = true
        PXLayout.pinLeft(view: button, to: containedButtonView, withMargin: PXLayout.S_MARGIN).isActive = true
        PXLayout.pinRight(view: button, to: containedButtonView, withMargin: PXLayout.S_MARGIN).isActive = true

        PXLayout.setHeight(owner: button, height: BUTTON_HEIGHT).isActive = true

        return containedButtonView
    }

    fileprivate func buildButton(with action:@escaping (() -> Void), title: String) -> PXAnimatedButton {
        let button = PXAnimatedButton(normalText: title, loadingText: "Procesando tu pago".localized, retryText: "Reintentar".localized)
        button.backgroundColor = ThemeManager.shared.getAccentColor()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.add(for: .touchUpInside, action)
        return button
    }
}

class PXContainedActionButtonView: UIView {
    public var button: PXAnimatedButton?
}
