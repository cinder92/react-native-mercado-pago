//
//  PXReviewViewModel.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 27/2/18.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import UIKit

class PXReviewViewModel: NSObject {

    var screenName: String { return TrackingUtil.SCREEN_NAME_REVIEW_AND_CONFIRM }
    var screenId: String { return TrackingUtil.SCREEN_ID_REVIEW_AND_CONFIRM }

    static let ERROR_DELTA = 0.001
    public static var CUSTOMER_ID = ""

    internal var amountHelper: PXAmountHelper
    var paymentOptionSelected: PaymentMethodOption
    var reviewScreenPreference: PXReviewConfirmConfiguration
    var userLogged: Bool

    public init(amountHelper: PXAmountHelper, paymentOptionSelected: PaymentMethodOption, reviewConfirmConfig: PXReviewConfirmConfiguration, userLogged: Bool) {
        PXReviewViewModel.CUSTOMER_ID = ""
        self.amountHelper = amountHelper
        self.paymentOptionSelected = paymentOptionSelected
        self.reviewScreenPreference = reviewConfirmConfig
        self.userLogged = userLogged
    }

    // MARK: Tracking logic
    func trackConfirmActionEvent() {
        var properties: [String: String] = [TrackingUtil.METADATA_PAYMENT_METHOD_ID: self.amountHelper.paymentData.paymentMethod?.id ?? "", TrackingUtil.METADATA_PAYMENT_TYPE_ID: self.amountHelper.paymentData.paymentMethod?.paymentTypeId ?? "", TrackingUtil.METADATA_AMOUNT_ID: String(describing: self.amountHelper.preferenceAmountWithCharges)]

        if let customerCard = paymentOptionSelected as? CustomerPaymentMethod {
            properties[TrackingUtil.METADATA_CARD_ID] = customerCard.customerPaymentMethodId
        }
        if let installments = amountHelper.paymentData.payerCost?.installments {
            properties[TrackingUtil.METADATA_INSTALLMENTS] = installments.stringValue
        }

        MPXTracker.sharedInstance.trackActionEvent(action: TrackingUtil.ACTION_CHECKOUT_CONFIRMED, screenId: screenId, screenName: screenName, properties: properties)
    }

    func trackInfo() {
        MPXTracker.sharedInstance.trackScreen(screenId: screenId, screenName: screenName)
    }

    func trackChangePaymentMethodEvent() {
        // No tracking for change payment method event in review view controller for now
    }
}

// MARK: - Logic.
extension PXReviewViewModel {

    // Logic.
    func isPaymentMethodSelectedCard() -> Bool {
        return self.amountHelper.paymentData.hasPaymentMethod() && self.amountHelper.paymentData.getPaymentMethod()!.isCard
    }

    func isPaymentMethodSelected() -> Bool {
        return self.amountHelper.paymentData.hasPaymentMethod()
    }

    func shouldShowTermsAndCondition() -> Bool {
        return !userLogged
    }

    func shouldShowDiscountTermsAndCondition() -> Bool {
        if self.amountHelper.discount != nil {
            return true
        }
        return false
    }

    func getDiscountTermsAndConditionView(shouldAddMargins: Bool = true) -> PXTermsAndConditionView {
        let discountTermsAndConditionView = PXDiscountTermsAndConditionView(amountHelper: amountHelper, shouldAddMargins: shouldAddMargins)
        return discountTermsAndConditionView
    }

    func shouldShowInstallmentSummary() -> Bool {
        return isPaymentMethodSelectedCard() && self.amountHelper.paymentData.getPaymentMethod()!.paymentTypeId != "debit_card" && self.amountHelper.paymentData.hasPayerCost() && self.amountHelper.paymentData.getPayerCost()!.installments != 1
    }

    func shouldDisplayNoRate() -> Bool {
        return self.amountHelper.paymentData.hasPayerCost() && !self.amountHelper.paymentData.getPayerCost()!.hasInstallmentsRate() && self.amountHelper.paymentData.getPayerCost()!.installments != 1
    }

    func hasPayerCostAddionalInfo() -> Bool {
        return self.amountHelper.paymentData.hasPayerCost() && self.amountHelper.paymentData.getPayerCost()!.getCFTValue() != nil && self.amountHelper.paymentData.paymentMethod!.isCreditCard
    }

    func hasConfirmAdditionalInfo() -> Bool {
        return hasPayerCostAddionalInfo() || needUnlockCardComponent()
    }

    func needUnlockCardComponent() -> Bool {
        return getUnlockLink() != nil
    }
}

// MARK: - Getters
extension PXReviewViewModel {

    func getTotalAmount() -> Double {
        return self.amountHelper.amountToPay
    }

    func getUnlockLink() -> URL? {
        let path = ResourceManager.shared.getBundle()!.path(forResource: "UnlockCardLinks", ofType: "plist")
        let dictionary = NSDictionary(contentsOfFile: path!)
        let site = SiteManager.shared.getSiteId()
        guard let issuerID = self.amountHelper.paymentData.getIssuer()?.id else {
            return nil
        }
        let searchString: String = site + "_" + "\(issuerID)"

        if let link = dictionary?.value(forKey: searchString) as? String {
            return URL(string: link)
        }

        return nil
    }

    func getClearPaymentData() -> PXPaymentData {
        let newPaymentData: PXPaymentData = self.amountHelper.paymentData.copy() as? PXPaymentData ?? self.amountHelper.paymentData
        newPaymentData.clearCollectedData()
        return newPaymentData
    }

    func getFloatingConfirmViewHeight() -> CGFloat {
        return 82 + PXLayout.getSafeAreaBottomInset()/2
    }

    func getSummaryViewModel(amount: Double) -> Summary {

        var summary: Summary
        let charge = self.amountHelper.chargeRuleAmount

        // TODO: Check Double type precision.
        if abs(amount - (self.reviewScreenPreference.getSummaryTotalAmount() + charge)) <= PXReviewViewModel.ERROR_DELTA {
            summary = Summary(details: self.reviewScreenPreference.details)
            if self.reviewScreenPreference.details[SummaryType.PRODUCT]?.details.count == 0 { //Si solo le cambio el titulo a Productos
                summary.addAmountDetail(detail: SummaryItemDetail(amount: self.amountHelper.preferenceAmount), type: SummaryType.PRODUCT)
            }
        } else {
            summary = getDefaultSummary()
            if self.reviewScreenPreference.details[SummaryType.PRODUCT]?.details.count == 0 { //Si solo le cambio el titulo a Productos
                if let title = self.reviewScreenPreference.details[SummaryType.PRODUCT]?.title {
                    summary.updateTitle(type: SummaryType.PRODUCT, oneWordTitle: title)
                }
            }
        }

        if charge > PXReviewViewModel.ERROR_DELTA {
            if let chargesTitle = self.reviewScreenPreference.summaryTitles[SummaryType.CHARGE] {
                let chargesAmountDetail = SummaryItemDetail(name: "", amount: charge)
                let chargesSummaryDetail = SummaryDetail(title: chargesTitle, detail: chargesAmountDetail)
                summary.addSummaryDetail(summaryDetail: chargesSummaryDetail, type: SummaryType.CHARGE)
            }
        }

        if let discount = self.amountHelper.paymentData.discount {
            let discountAmountDetail = SummaryItemDetail(name: discount.description, amount: discount.couponAmount)

            if summary.details[SummaryType.DISCOUNT] != nil {
                summary.addAmountDetail(detail: discountAmountDetail, type: SummaryType.DISCOUNT)
            } else {
                let discountSummaryDetail = SummaryDetail(title: self.reviewScreenPreference.summaryTitles[SummaryType.DISCOUNT]!, detail: discountAmountDetail)
                summary.addSummaryDetail(summaryDetail: discountSummaryDetail, type: SummaryType.DISCOUNT)
            }
            summary.details[SummaryType.DISCOUNT]?.titleColor = ThemeManager.shared.noTaxAndDiscountLabelTintColor()
            summary.details[SummaryType.DISCOUNT]?.amountColor = ThemeManager.shared.noTaxAndDiscountLabelTintColor()
        }
        if self.amountHelper.paymentData.payerCost != nil {
            var interest = 0.0

            if (self.amountHelper.paymentData.discount?.couponAmount) != nil {
                interest = self.amountHelper.amountToPay - (self.amountHelper.preferenceAmountWithCharges - self.amountHelper.amountOff)
            } else {
                interest = self.amountHelper.amountToPay - self.amountHelper.preferenceAmountWithCharges
            }

            if interest > PXReviewViewModel.ERROR_DELTA {
                let interestAmountDetail = SummaryItemDetail(amount: interest)
                if summary.details[SummaryType.CHARGE] != nil {
                    summary.addAmountDetail(detail: interestAmountDetail, type: SummaryType.CHARGE)
                } else {
                    let interestSummaryDetail = SummaryDetail(title: self.reviewScreenPreference.summaryTitles[SummaryType.CHARGE]!, detail: interestAmountDetail)
                    summary.addSummaryDetail(summaryDetail: interestSummaryDetail, type: SummaryType.CHARGE)
                }
            }
        }
        if let disclaimer = self.reviewScreenPreference.getDisclaimerText() {
            summary.disclaimer = disclaimer
            summary.disclaimerColor = self.reviewScreenPreference.getDisclaimerTextColor()
        }
        return summary
    }

    func getDefaultSummary() -> Summary {
        let productSummaryDetail = SummaryDetail(title: self.reviewScreenPreference.summaryTitles[SummaryType.PRODUCT]!, detail: SummaryItemDetail(amount: self.amountHelper.preferenceAmount))

        return Summary(details: [SummaryType.PRODUCT: productSummaryDetail])
    }
}

// MARK: - Components builders.
extension PXReviewViewModel {

    func buildPaymentMethodComponent(withAction: PXAction?) -> PXPaymentMethodComponent? {

        guard let pm = self.amountHelper.paymentData.getPaymentMethod() else {
            return nil
        }

        let issuer = self.amountHelper.paymentData.getIssuer()
        let paymentMethodName = pm.name ?? ""
        let paymentMethodIssuerName = issuer?.name ?? ""

        let image = PXImageService.getIconImageFor(paymentMethod: pm)
        var title = NSAttributedString(string: "")
        var subtitle: NSAttributedString? = pm.paymentMethodDescription?.toAttributedString()
        var accreditationTime: NSAttributedString? = nil
        var action = withAction
        let backgroundColor = ThemeManager.shared.detailedBackgroundColor()
        let lightLabelColor = ThemeManager.shared.labelTintColor()
        let boldLabelColor = ThemeManager.shared.boldLabelTintColor()

        if pm.isCard {
            if let lastFourDigits = (self.amountHelper.paymentData.token?.lastFourDigits) {
                let text = paymentMethodName + " " + "terminada en ".localized + lastFourDigits
                title = text.toAttributedString()
            }
        } else {
            title = paymentMethodName.toAttributedString()
            if paymentOptionSelected.getComment().isNotEmpty {
                accreditationTime = Utils.getAccreditationTimeAttributedString(from: paymentOptionSelected.getComment())
            }
        }

        if paymentMethodIssuerName.lowercased() != paymentMethodName.lowercased() && !paymentMethodIssuerName.isEmpty {
            subtitle = paymentMethodIssuerName.toAttributedString()
        }

        if !self.reviewScreenPreference.isChangeMethodOptionEnabled() {
            action = nil
        }

        let props = PXPaymentMethodProps(paymentMethodIcon: image, title: title, subtitle: subtitle, descriptionTitle: nil, descriptionDetail: accreditationTime, disclaimer: nil, action: action, backgroundColor: backgroundColor, lightLabelColor: lightLabelColor, boldLabelColor: boldLabelColor)

        return PXPaymentMethodComponent(props: props)
    }

    func buildSummaryComponent(width: CGFloat) -> PXSummaryComponent {

        var customTitle = "Productos".localized
        let totalAmount: Double = self.amountHelper.preferenceAmountWithCharges
        if let prefDetail = reviewScreenPreference.details[SummaryType.PRODUCT], !prefDetail.title.isEmpty {
            customTitle = prefDetail.title
        } else {
            if self.amountHelper.preference.items.count == 1 {
                if let itemTitle = self.amountHelper.preference.items.first?.title, itemTitle.count > 0 {
                    customTitle = itemTitle
                }
            }
        }

        let props = PXSummaryComponentProps(summaryViewModel: getSummaryViewModel(amount: totalAmount), amountHelper: amountHelper, width: width, customTitle: customTitle, textColor: ThemeManager.shared.boldLabelTintColor(), backgroundColor: ThemeManager.shared.highlightBackgroundColor())

        return PXSummaryComponent(props: props)
    }

    func buildTitleComponent() -> PXReviewTitleComponent {
        let props = PXReviewTitleComponentProps(titleColor: ThemeManager.shared.getTitleColorForReviewConfirmNavigation(), backgroundColor: ThemeManager.shared.highlightBackgroundColor())
        return PXReviewTitleComponent(props: props)
    }
}

// MARK: Item component
extension PXReviewViewModel {

    // HotFix: TODO - Move to OneTapViewModel
    func buildOneTapItemComponents() -> [PXItemComponent] {
        var pxItemComponents = [PXItemComponent]()
        if reviewScreenPreference.hasItemsEnabled() {
            for item in self.amountHelper.preference.items {
                if let itemComponent = buildOneTapItemComponent(item: item) {
                    pxItemComponents.append(itemComponent)
                }
            }
        }
        return pxItemComponents
    }

    func buildItemComponents() -> [PXItemComponent] {
        var pxItemComponents = [PXItemComponent]()
        if reviewScreenPreference.hasItemsEnabled() { // Items can be disable
            for item in self.amountHelper.preference.items {
                if let itemComponent = buildItemComponent(item: item) {
                    pxItemComponents.append(itemComponent)
                }
            }
        }
        return pxItemComponents
    }

    fileprivate func shouldShowQuantity(item: PXItem) -> Bool {
        return item.quantity > 1 // Quantity must not be shown if it is 1
    }

    fileprivate func shouldShowPrice(item: PXItem) -> Bool {
        return amountHelper.preference.hasMultipleItems() || item.quantity > 1 // Price must not be shown if quantity is 1 and there are no more products
    }

    fileprivate func shouldShowCollectorIcon() -> Bool {
        return !amountHelper.preference.hasMultipleItems() && reviewScreenPreference.getCollectorIcon() != nil
    }

    fileprivate func buildItemComponent(item: PXItem) -> PXItemComponent? {
        if item.quantity == 1 && String.isNullOrEmpty(item._description) && !amountHelper.preference.hasMultipleItems() { // Item must not be shown if it has no description and it's one
            return nil
        }

        let itemQuantiy = getItemQuantity(item: item)
        let itemPrice = getItemPrice(item: item)
        let itemTitle = getItemTitle(item: item)
        let itemDescription = getItemDescription(item: item)
        let collectorIcon = getCollectorIcon()
        let amountTitle = reviewScreenPreference.getAmountTitle()
        let quantityTile = reviewScreenPreference.getQuantityLabel()

        let itemTheme: PXItemComponentProps.ItemTheme = (backgroundColor: ThemeManager.shared.detailedBackgroundColor(), boldLabelColor: ThemeManager.shared.boldLabelTintColor(), lightLabelColor: ThemeManager.shared.labelTintColor())

        let itemProps = PXItemComponentProps(imageURL: item.pictureUrl, title: itemTitle, description: itemDescription, quantity: itemQuantiy, unitAmount: itemPrice, amountTitle: amountTitle, quantityTitle: quantityTile, collectorImage: collectorIcon, itemTheme: itemTheme)
        return PXItemComponent(props: itemProps)
    }

    // HotFix: TODO - Move to OneTapViewModel
    private func buildOneTapItemComponent(item: PXItem) -> PXItemComponent? {
        let itemQuantiy = item.quantity
        let itemPrice = item.unitPrice
        let itemTitle = item.title
        let itemDescription = item._description

        let itemTheme: PXItemComponentProps.ItemTheme = (backgroundColor: ThemeManager.shared.detailedBackgroundColor(), boldLabelColor: ThemeManager.shared.boldLabelTintColor(), lightLabelColor: ThemeManager.shared.labelTintColor())

        let itemProps = PXItemComponentProps(imageURL: item.pictureUrl, title: itemTitle, description: itemDescription, quantity: itemQuantiy, unitAmount: itemPrice, amountTitle: "", quantityTitle: "", collectorImage: nil, itemTheme: itemTheme)
        return PXItemComponent(props: itemProps)
    }
}

// MARK: Item getters
extension PXReviewViewModel {
    fileprivate func getItemTitle(item: PXItem) -> String? { // Return item real title if it has multiple items, if not return description
        if amountHelper.preference.hasMultipleItems() {
            return item.title
        }
        return item._description
    }

    fileprivate func getItemDescription(item: PXItem) -> String? { // Returns only if it has multiple items
        if amountHelper.preference.hasMultipleItems() {
            return item._description
        }
        return nil
    }

    fileprivate func getItemQuantity(item: PXItem) -> Int? {
        if  !shouldShowQuantity(item: item) {
            return nil
        }
        return item.quantity
    }

    fileprivate func getItemPrice(item: PXItem) -> Double? {
        if  !shouldShowPrice(item: item) {
            return nil
        }
        return item.unitPrice
    }

    fileprivate func getCollectorIcon() -> UIImage? {
        if !shouldShowCollectorIcon() {
            return nil
        }
        return reviewScreenPreference.getCollectorIcon()
    }
}

// MARK: Custom Views
extension PXReviewViewModel {
    func buildTopCustomView() -> UIView? {
        if let customView = reviewScreenPreference.getTopCustomView() {
            return buildComponentView(customView)
        }
        return nil
    }

    func buildBottomCustomView() -> UIView? {
        if let customView = reviewScreenPreference.getBottomCustomView() {
            return buildComponentView(customView)
        }
        return nil
    }

    private func buildComponentView(_ customView: UIView) -> UIView {
        let componentView = UIView()
        componentView.translatesAutoresizingMaskIntoConstraints = false
        customView.translatesAutoresizingMaskIntoConstraints = false
        PXLayout.setHeight(owner: customView, height: customView.frame.height).isActive = true
        componentView.addSubview(customView)
        PXLayout.centerHorizontally(view: customView).isActive = true
        PXLayout.pinTop(view: customView).isActive = true
        PXLayout.pinBottom(view: customView).isActive = true
        PXLayout.matchWidth(ofView: customView).isActive = true
        return componentView
    }
}
