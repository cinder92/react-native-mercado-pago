//
//  PXFooterProps.swift
//  MercadoPagoSDK
//
//  Created by Juan sebastian Sanzone on 16/5/18.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation

final class PXFooterProps: NSObject {
    var buttonAction: PXAction?
    var linkAction: PXAction?
    var primaryColor: UIColor?
    var animationDelegate: PXAnimatedButtonDelegate?
    var pinLastSubviewToBottom: Bool
    init(buttonAction: PXAction? = nil, linkAction: PXAction? = nil, primaryColor: UIColor? = ThemeManager.shared.getAccentColor(), animationDelegate: PXAnimatedButtonDelegate? = nil, pinLastSubviewToBottom: Bool = true) {
        self.buttonAction = buttonAction
        self.linkAction = linkAction
        self.primaryColor = primaryColor
        self.animationDelegate = animationDelegate
        self.pinLastSubviewToBottom = pinLastSubviewToBottom
    }
}
