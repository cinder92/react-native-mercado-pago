//
//  MercadoPagoCheckoutBuilder.swift
//  MercadoPagoSDK
//
//  Created by Juan sebastian Sanzone on 9/8/18.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import Foundation

/**
 Checkout builder allow you to create a `MercadoPagoCheckout`. This is the only way to create `MercadoPagoCheckout` object.
 */
@objcMembers
open class MercadoPagoCheckoutBuilder: NSObject {
    internal let publicKey: String
    internal var preferenceId: String?
    internal var checkoutPreference: PXCheckoutPreference?

    internal var privateKey: String?

    internal var paymentConfig: PXPaymentConfiguration?
    internal var advancedConfig: PXAdvancedConfiguration?

    internal var defaultUIColor: UIColor?

    // MARK: Initialization
    /**
     Mandatory init.
     - parameter publicKey: Merchant public key / collector public key
     - parameter preferenceId: The preference id that represents the payment information.
     */
    public init(publicKey: String, preferenceId: String) {
        self.publicKey = publicKey
        self.preferenceId = preferenceId
    }

    /**
     Mandatory init.
     - parameter publicKey: Merchant public key / collector public key.
     - parameter preferenceId: The preference id that represents the payment information.
     - parameter paymentConfiguration: The payment configuration object for this checkout.
     */
    public init(publicKey: String, preferenceId: String, paymentConfiguration: PXPaymentConfiguration) {
        self.publicKey = publicKey
        self.preferenceId = preferenceId
        self.paymentConfig = paymentConfiguration
    }

    /**
     Mandatory init.
     - parameter publicKey: Merchant public key / collector public key.
     - parameter checkoutPreference: The preference that represents the payment information.
     - parameter paymentConfiguration: The payment configuration for this checkout.
     */
    public init(publicKey: String, checkoutPreference: PXCheckoutPreference, paymentConfiguration: PXPaymentConfiguration) {
        self.publicKey = publicKey
        self.checkoutPreference = checkoutPreference
        self.paymentConfig = paymentConfiguration
    }
}

// MARK: - Setters/Builders
extension MercadoPagoCheckoutBuilder {
    /**
     Private key provides save card capabilities and account money balance. (User logged)
     - parameter privateKey: The user private key
     */
    @discardableResult
    open func setPrivateKey(key: String) -> MercadoPagoCheckoutBuilder {
        self.privateKey = key
        return self
    }

    /**
     It provides support for custom checkout functionality/configure special behaviour
     You can enable/disable several functionality.
     - parameter config: `PXAdvancedConfiguration` object.
     */
    @discardableResult
    open func setAdvancedConfiguration(config: PXAdvancedConfiguration) -> MercadoPagoCheckoutBuilder {
        self.advancedConfig = config
        return self
    }

    /**
     You can set one color (your primary color) and we will take care of the rest. Delivering the best Checkout experience based on your color. If you need more customization explore `PXTheme` inside `PXAdvancedConfiguration`.
     - parameter checkoutColor: Your primary color.
     */
    @discardableResult
    open func setColor(checkoutColor: UIColor) -> MercadoPagoCheckoutBuilder {
        self.defaultUIColor = checkoutColor
        return self
    }

    /**
     You can set the Language locale string. (`es` is the default value). For more values explore our `PXLanguages` public enum.
     - parameter _string: Your locale string Language.
     */
    @discardableResult
    open func setLanguage(_ string: String) -> MercadoPagoCheckoutBuilder {
        Localizator.sharedInstance.setLanguage(string: string)
        return self
    }
}
