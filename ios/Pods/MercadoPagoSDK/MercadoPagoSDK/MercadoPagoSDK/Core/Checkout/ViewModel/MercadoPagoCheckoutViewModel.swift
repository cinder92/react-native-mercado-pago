//
//  CheckoutViewModel.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 1/23/17.
//  Copyright © 2017 MercadoPago. All rights reserved.
//

import UIKit

internal enum CheckoutStep: String {
    case START
    case ACTION_FINISH
    case SERVICE_GET_IDENTIFICATION_TYPES
    case SCREEN_PAYMENT_METHOD_SELECTION
    case SCREEN_CARD_FORM
    case SCREEN_SECURITY_CODE
    case SERVICE_GET_ISSUERS
    case SCREEN_ISSUERS
    case SERVICE_CREATE_CARD_TOKEN
    case SCREEN_IDENTIFICATION
    case SCREEN_ENTITY_TYPE
    case SCREEN_FINANCIAL_INSTITUTIONS
    case SERVICE_GET_PAYER_COSTS
    case SCREEN_PAYER_INFO_FLOW
    case SCREEN_PAYER_COST
    case SCREEN_REVIEW_AND_CONFIRM
    case SERVICE_POST_PAYMENT

    case SCREEN_PAYMENT_RESULT
    case SCREEN_ERROR
    case SCREEN_HOOK_BEFORE_PAYMENT_METHOD_CONFIG
    case SCREEN_HOOK_AFTER_PAYMENT_METHOD_CONFIG
    case SCREEN_HOOK_BEFORE_PAYMENT
    case SCREEN_PAYMENT_METHOD_PLUGIN_CONFIG
    case FLOW_ONE_TAP
}

internal class MercadoPagoCheckoutViewModel: NSObject, NSCopying {

    var hookService: HookService = HookService()

    private var advancedConfig: PXAdvancedConfiguration = PXAdvancedConfiguration()

    internal var publicKey: String
    internal var privateKey: String?

    var lifecycleProtocol: PXLifeCycleProtocol?

    var consumedDiscount: Bool = false
    // In order to ensure data updated create new instance for every usage
    var amountHelper: PXAmountHelper {
        get {
            return PXAmountHelper(preference: self.checkoutPreference, paymentData: self.paymentData.copy() as! PXPaymentData, discount: self.paymentData.discount, campaign: self.paymentData.campaign, chargeRules: self.chargeRules, consumedDiscount: consumedDiscount)
        }
    }
    var checkoutPreference: PXCheckoutPreference!
    let mercadoPagoServicesAdapter: MercadoPagoServicesAdapter

    //    var paymentMethods: [PaymentMethod]?
    var cardToken: PXCardToken?
    var customerId: String?

    // Payment methods disponibles en selección de medio de pago
    var paymentMethodOptions: [PaymentMethodOption]?
    var paymentOptionSelected: PaymentMethodOption?
    // Payment method disponibles correspondientes a las opciones que se muestran en selección de medio de pago
    var availablePaymentMethods: [PXPaymentMethod]?

    var rootPaymentMethodOptions: [PaymentMethodOption]?
    var customPaymentOptions: [CustomerPaymentMethod]?
    var identificationTypes: [PXIdentificationType]?

    var search: PXPaymentMethodSearch?

    var rootVC = true

    internal var paymentData = PXPaymentData()
    var payment: PXPayment?
    internal var paymentResult: PaymentResult?
    var businessResult: PXBusinessResult?
    open var payerCosts: [PXPayerCost]?
    open var issuers: [PXIssuer]?
    open var entityTypes: [EntityType]?
    open var financialInstitutions: [PXFinancialInstitution]?
    open var instructionsInfo: PXInstructions?

    static var error: MPSDKError?

    var errorCallback: (() -> Void)?

    var readyToPay: Bool = false
    var initWithPaymentData = false
    var savedESCCardToken: PXSavedESCCardToken?
    private var checkoutComplete = false
    var paymentMethodConfigPluginShowed = false

    var mpESCManager: MercadoPagoESC = MercadoPagoESCImplementation(enabled: false)

    // Plugins payment method.
    var paymentMethodPlugins = [PXPaymentMethodPlugin]()
    var paymentMethodPluginsToShow = [PXPaymentMethodPlugin]()

    // Payment plugin
    var paymentPlugin: PXPaymentProcessor?
    var paymentFlow: PXPaymentFlow?

    // Discount and charges
    var chargeRules: [PXPaymentTypeChargeRule]?
    var campaigns: [PXCampaign]?

    // Init Flow
    var initFlow: InitFlow?
    weak var initFlowProtocol: InitFlowProtocol?

    lazy var pxNavigationHandler: PXNavigationHandler = PXNavigationHandler.getDefault()

    init(checkoutPreference: PXCheckoutPreference, publicKey: String, privateKey: String?) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.checkoutPreference = checkoutPreference

        mercadoPagoServicesAdapter = MercadoPagoServicesAdapter(publicKey: publicKey, privateKey: privateKey)

        super.init()

        if !isPreferenceLoaded() {
            self.paymentData.payer = self.checkoutPreference.getPayer()
        }

        // Create Init Flow
        createInitFlow()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copyObj = MercadoPagoCheckoutViewModel(checkoutPreference: self.checkoutPreference, publicKey: publicKey, privateKey: privateKey)
        copyObj.setNavigationHandler(handler: pxNavigationHandler)
        return copyObj
    }

    func setNavigationHandler(handler: PXNavigationHandler) {
        pxNavigationHandler = handler
    }

    func hasError() -> Bool {
        return MercadoPagoCheckoutViewModel.error != nil
    }

    func setDiscount(_ discount: PXDiscount, withCampaign campaign: PXCampaign) {
        self.paymentData.setDiscount(discount, withCampaign: campaign)
    }

    func clearDiscount() {
        self.paymentData.clearDiscount()
    }

    public func getPaymentPreferences() -> PXPaymentPreference? {
        return self.checkoutPreference.paymentPreference
    }

    public func cardFormManager() -> CardFormViewModel {
        return CardFormViewModel(paymentMethods: getPaymentMethodsForSelection(), mercadoPagoServicesAdapter: mercadoPagoServicesAdapter, bankDealsEnabled: advancedConfig.bankDealsEnabled)
    }

    public func getPaymentMethodsForSelection() -> [PXPaymentMethod] {
        let filteredPaymentMethods = search?.paymentMethods.filter {
            return $0.conformsPaymentPreferences(self.getPaymentPreferences()) && $0.paymentTypeId ==  self.paymentOptionSelected?.getId()
        }
        guard let paymentMethods = filteredPaymentMethods else {
            return []
        }
        return paymentMethods
    }

    func payerInfoFlow() -> PayerInfoViewModel {
        let viewModel = PayerInfoViewModel(identificationTypes: self.identificationTypes!, payer: self.paymentData.payer!)
        return viewModel
    }

    func getPluginPaymentMethodToShow() -> [PXPaymentMethodPlugin] {
        populateCheckoutStore()
        return paymentMethodPlugins.filter {$0.mustShowPaymentMethodPlugin(PXCheckoutStore.sharedInstance) == true}
    }

    // Returns lists of all payment option available
    fileprivate func getPaymentMethodsOptions(_ paymentMethodPluginsToShow: [PXPaymentMethodPlugin]) -> String {
        var paymentMethodsOptions = ""

        if let paymentMethods = search?.paymentMethods {
            for paymentMethod in paymentMethods {
                if let id = paymentMethod.id {
                    paymentMethodsOptions += "\(id):\(paymentMethod.paymentTypeId)|"
                }
            }
        }

        if let customPaymentOptions = customPaymentOptions {
            for customCard in customPaymentOptions {
                paymentMethodsOptions += "\(customCard.getPaymentMethodId()):\(customCard.getPaymentTypeId()):\(customCard.getCardId())"
                if mpESCManager.getESC(cardId: customCard.getCardId()) != nil {
                    paymentMethodsOptions += ":ESC"
                }
                paymentMethodsOptions += "|"
            }
        }

        for paymentMethodPlugin in paymentMethodPluginsToShow {
            paymentMethodsOptions += "\(paymentMethodPlugin.getId()):\(PXPaymentTypes.PAYMENT_METHOD_PLUGIN.rawValue)|"
        }
        paymentMethodsOptions = String(paymentMethodsOptions.dropLast())
        return paymentMethodsOptions
    }

    func paymentVaultViewModel() -> PaymentVaultViewModel {
        var groupName: String?
        if let optionSelected = paymentOptionSelected {
            groupName = optionSelected.getId()
        }

        populateCheckoutStore()
        let paymentMethodPluginsToShow = paymentMethodPlugins.filter {$0.mustShowPaymentMethodPlugin(PXCheckoutStore.sharedInstance) == true}

        // Get payment methods options for tracking in PaymentVault
        let paymentMethodsOptions = getPaymentMethodsOptions(paymentMethodPluginsToShow)
        PXTrackingStore.sharedInstance.addData(forKey: PXTrackingStore.PAYMENT_METHOD_OPTIONS, value: paymentMethodsOptions)

        return PaymentVaultViewModel(amountHelper: self.amountHelper, paymentMethodOptions: self.paymentMethodOptions!, customerPaymentOptions: self.customPaymentOptions, paymentMethodPlugins: paymentMethodPluginsToShow, groupName: groupName, isRoot: rootVC, email: self.checkoutPreference.payer.email, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter, couponCallback: {[weak self] (_) in
            if self == nil {
                return
            }
            // object.paymentData.discount = discount // TODO SET DISCOUNT WITH CAMPAIGN
        })
    }

    public func entityTypeViewModel() -> AdditionalStepViewModel {
        return EntityTypeViewModel(amountHelper: self.amountHelper, token: self.cardToken, paymentMethod: self.paymentData.getPaymentMethod()!, dataSource: self.entityTypes!, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter)
    }

    public func financialInstitutionViewModel() -> AdditionalStepViewModel {
        return FinancialInstitutionViewModel(amountHelper: self.amountHelper, token: self.cardToken, paymentMethod: self.paymentData.getPaymentMethod()!, dataSource: self.financialInstitutions!, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter)
    }

    public func issuerViewModel() -> AdditionalStepViewModel {
        guard let paymentMethod = self.paymentData.getPaymentMethod() else {
            fatalError("Cannot find payment method")
        }

        return IssuerAdditionalStepViewModel(amountHelper: self.amountHelper, token: self.cardToken, paymentMethod: paymentMethod, dataSource: self.issuers!, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter)
    }

    public func payerCostViewModel() -> AdditionalStepViewModel {
        guard let paymentMethod = self.paymentData.getPaymentMethod() else {
            fatalError("Cannot find payment method")
        }
        var cardInformation: PXCardInformationForm? = self.cardToken
        if cardInformation == nil {
            if let token = paymentOptionSelected as? PXCardInformationForm {
                cardInformation = token
            }
        }

        return PayerCostAdditionalStepViewModel(amountHelper: self.amountHelper, token: cardInformation, paymentMethod: paymentMethod, dataSource: payerCosts!, email: self.checkoutPreference.payer.email, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter)
    }

    public func savedCardSecurityCodeViewModel() -> SecurityCodeViewModel {
        guard let cardInformation = self.paymentOptionSelected as? PXCardInformation else {
            fatalError("Cannot conver payment option selected to CardInformation")
        }
        var reason: SecurityCodeViewModel.Reason
        if paymentResult != nil && paymentResult!.isInvalidESC() {
            reason = SecurityCodeViewModel.Reason.INVALID_ESC
        } else {
            reason = SecurityCodeViewModel.Reason.SAVED_CARD
        }
        return SecurityCodeViewModel(paymentMethod: self.paymentData.paymentMethod!, cardInfo: cardInformation, reason: reason)
    }

    public func cloneTokenSecurityCodeViewModel() -> SecurityCodeViewModel {
        let cardInformation = self.paymentData.token
        let reason = SecurityCodeViewModel.Reason.CALL_FOR_AUTH
        return SecurityCodeViewModel(paymentMethod: self.paymentData.paymentMethod!, cardInfo: cardInformation!, reason: reason)
    }

    func reviewConfirmViewModel() -> PXReviewViewModel {
        return PXReviewViewModel(amountHelper: self.amountHelper, paymentOptionSelected: self.paymentOptionSelected!, reviewConfirmConfig: advancedConfig.reviewConfirmConfiguration, userLogged: !String.isNullOrEmpty(privateKey))
    }

    func resultViewModel() -> PXResultViewModel {
        return PXResultViewModel(amountHelper: self.amountHelper, paymentResult: self.paymentResult!, instructionsInfo: self.instructionsInfo, resultConfiguration: self.advancedConfig.paymentResultConfiguration)
    }

    //SEARCH_PAYMENT_METHODS
    public func updateCheckoutModel(paymentMethods: [PXPaymentMethod], cardToken: PXCardToken?) {
        self.cleanPayerCostSearch()
        self.cleanIssuerSearch()
        self.cleanIdentificationTypesSearch()
        self.paymentData.updatePaymentDataWith(paymentMethod: paymentMethods[0])
        self.cardToken = cardToken
    }

    //CREDIT_DEBIT
    public func updateCheckoutModel(paymentMethod: PXPaymentMethod?) {
        if let paymentMethod = paymentMethod {
            self.paymentData.updatePaymentDataWith(paymentMethod: paymentMethod)
        }
    }

    public func updateCheckoutModel(financialInstitution: PXFinancialInstitution) {
        if let TDs = self.paymentData.transactionDetails {
            TDs.financialInstitution = financialInstitution.id
        } else {
            let transactionDetails = PXTransactionDetails(externalResourceUrl: nil, financialInstitution: financialInstitution.id, installmentAmount: nil, netReivedAmount: nil, overpaidAmount: nil, totalPaidAmount: nil, paymentMethodReferenceId: nil)
            self.paymentData.transactionDetails = transactionDetails
        }
    }

    public func updateCheckoutModel(issuer: PXIssuer) {
        self.cleanPayerCostSearch()
        self.paymentData.updatePaymentDataWith(issuer: issuer)
    }

    public func updateCheckoutModel(payer: PXPayer) {
        self.paymentData.updatePaymentDataWith(payer: payer)
    }

    public func updateCheckoutModel(identificationTypes: [PXIdentificationType]) {
        self.identificationTypes = identificationTypes
    }

    public func updateCheckoutModel(identification: PXIdentification) {
        self.paymentData.cleanToken()
        self.paymentData.cleanIssuer()
        self.paymentData.cleanPayerCost()
        self.cleanPayerCostSearch()
        self.cleanIssuerSearch()

        if paymentData.hasPaymentMethod() && paymentData.getPaymentMethod()!.isCard {
            self.cardToken!.cardholder!.identification = identification
        } else {
            paymentData.payer?.identification = identification
        }
    }

    public func updateCheckoutModel(payerCost: PXPayerCost) {
        self.paymentData.updatePaymentDataWith(payerCost: payerCost)

        if let paymentOptionSelected = paymentOptionSelected {
            if paymentOptionSelected.isCustomerPaymentMethod() {
                self.paymentData.cleanToken()
            }
        }
    }

    public func updateCheckoutModel(entityType: EntityType) {
        self.paymentData.payer?.entityType = entityType.entityTypeId
    }

    // MARK: PAYMENT METHOD OPTION SELECTION
    public func updateCheckoutModel(paymentOptionSelected: PaymentMethodOption) {
        if !self.initWithPaymentData {
            resetInFormationOnNewPaymentMethodOptionSelected()
        }
        resetPaymentOptionSelectedWith(newPaymentOptionSelected: paymentOptionSelected)
    }

    public func resetPaymentOptionSelectedWith(newPaymentOptionSelected: PaymentMethodOption) {
        self.paymentOptionSelected = newPaymentOptionSelected

        if let targetPlugin = paymentOptionSelected as? PXPaymentMethodPlugin {
            self.paymentMethodPluginToPaymentMethod(plugin: targetPlugin)
            return
        }

        if newPaymentOptionSelected.hasChildren() {
            self.paymentMethodOptions =  newPaymentOptionSelected.getChildren()
        }

        if self.paymentOptionSelected!.isCustomerPaymentMethod() {
            self.findAndCompletePaymentMethodFor(paymentMethodId: newPaymentOptionSelected.getId())
        } else if !newPaymentOptionSelected.isCard() && !newPaymentOptionSelected.hasChildren() {
            self.paymentData.updatePaymentDataWith(paymentMethod: Utils.findPaymentMethod(self.availablePaymentMethods!, paymentMethodId: newPaymentOptionSelected.getId()))
        }
    }

    public func nextStep() -> CheckoutStep {

        if needToInitFlow() {
            return .START
        }

        if hasError() {
            return .SCREEN_ERROR
        }

        if shouldExitCheckout() {
            return .ACTION_FINISH
        }

        if shouldShowCongrats() {
            return .SCREEN_PAYMENT_RESULT
        }

        if needOneTapFlow() {
            return .FLOW_ONE_TAP
        }

        if !isPaymentTypeSelected() {
            return .SCREEN_PAYMENT_METHOD_SELECTION
        }

        if shouldShowHook(hookStep: .BEFORE_PAYMENT_METHOD_CONFIG) {
            return .SCREEN_HOOK_BEFORE_PAYMENT_METHOD_CONFIG
        }

        if needToShowPaymentMethodConfigPlugin() {
            willShowPaymentMethodConfigPlugin()
            return .SCREEN_PAYMENT_METHOD_PLUGIN_CONFIG
        }

        if shouldShowHook(hookStep: .AFTER_PAYMENT_METHOD_CONFIG) {
            return .SCREEN_HOOK_AFTER_PAYMENT_METHOD_CONFIG
        }

        if shouldShowHook(hookStep: .BEFORE_PAYMENT) {
            return .SCREEN_HOOK_BEFORE_PAYMENT
        }

        if needToCreatePayment() {
            readyToPay = false
            return .SERVICE_POST_PAYMENT
        }

        if needReviewAndConfirm() {
            return .SCREEN_REVIEW_AND_CONFIRM
        }

        if needCompleteCard() {
            return .SCREEN_CARD_FORM
        }

        if needToGetIdentificationTypes() {
            return .SERVICE_GET_IDENTIFICATION_TYPES
        }

        if needToGetPayerInfo() {
            return .SCREEN_PAYER_INFO_FLOW
        }

        if needGetIdentification() {
            return .SCREEN_IDENTIFICATION
        }

        if needSecurityCode() {
            return .SCREEN_SECURITY_CODE
        }

        if needCreateToken() {
            return .SERVICE_CREATE_CARD_TOKEN
        }

        if needGetEntityTypes() {
            return .SCREEN_ENTITY_TYPE
        }

        if needGetFinancialInstitutions() {
            return .SCREEN_FINANCIAL_INSTITUTIONS
        }

        if needGetIssuers() {
            return .SERVICE_GET_ISSUERS
        }

        if needIssuerSelectionScreen() {
            return .SCREEN_ISSUERS
        }

        if needChosePayerCost() {
            return .SERVICE_GET_PAYER_COSTS
        }

        if needPayerCostSelectionScreen() {
            return .SCREEN_PAYER_COST
        }

        return .ACTION_FINISH
    }

    fileprivate func autoselectOnlyPaymentMethod() {
        guard let search = self.search else {
            return
        }

        if !search.paymentMethods.isEmpty, !search.paymentMethods[0].isCard {
            self.advancedConfig.reviewConfirmConfiguration.disableChangeMethodOption()
        }

        if !Array.isNullOrEmpty(search.paymentMethodSearchItem) && search.paymentMethodSearchItem.count == 1 {
            self.updateCheckoutModel(paymentOptionSelected: search.paymentMethodSearchItem[0])
        } else if !Array.isNullOrEmpty(search.customOptionSearchItems) && search.customOptionSearchItems.count == 1 {
            guard let customOption = search.customOptionSearchItems[0] as? PaymentMethodOption else {
                fatalError("Cannot conver customerPaymentMethod to PaymentMethodOption")
            }
            self.updateCheckoutModel(paymentOptionSelected: customOption)
        } else if  !Array.isNullOrEmpty(paymentMethodPluginsToShow) && paymentMethodPluginsToShow.count == 1 {
            self.updateCheckoutModel(paymentOptionSelected: paymentMethodPluginsToShow[0])
        }
    }

    public func updateCheckoutModel(paymentMethodSearch: PXPaymentMethodSearch) {

        self.search = paymentMethodSearch

        guard let search = self.search else {
            return
        }

        self.rootPaymentMethodOptions = paymentMethodSearch.paymentMethodSearchItem
        self.paymentMethodOptions = self.rootPaymentMethodOptions
        self.availablePaymentMethods = paymentMethodSearch.paymentMethods
        customPaymentOptions?.removeAll()
        for pxCustomOptionSearchItem in search.customOptionSearchItems {
            // Removemos account_money como opción de pago (Warning: Until AM First Class Member)
            if pxCustomOptionSearchItem.paymentMethodId != PXPaymentTypes.ACCOUNT_MONEY.rawValue {
                let customerPaymentMethod =  pxCustomOptionSearchItem.getCustomerPaymentMethod()
                if let paymentMethodSearchCards = paymentMethodSearch.cards {
                    var filteredCustomerCard = paymentMethodSearchCards.filter({return $0.id == customerPaymentMethod.customerPaymentMethodId})
                    if !Array.isNullOrEmpty(filteredCustomerCard) {
                        customerPaymentMethod.card = filteredCustomerCard[0]
                    }
                }
                customPaymentOptions = Array.safeAppend(customPaymentOptions, customerPaymentMethod)
            }
        }

        let totalPaymentMethodSearchCount = search.getPaymentOptionsCount()
        self.paymentMethodPluginsToShow = getPluginPaymentMethodToShow()
        let totalPaymentMethodsToShow =  totalPaymentMethodSearchCount + paymentMethodPluginsToShow.count

        if totalPaymentMethodsToShow == 0 {
            self.errorInputs(error: MPSDKError(message: "Hubo un error".localized, errorDetail: "No se ha podido obtener los métodos de pago con esta preferencia".localized, retry: false), errorCallback: { () in
            })
        } else if totalPaymentMethodsToShow == 1 {
            autoselectOnlyPaymentMethod()
        }

        // MoneyIn "ChoExpress"
        if let defaultPM = getPreferenceDefaultPaymentOption() {
            updateCheckoutModel(paymentOptionSelected: defaultPM)
        }
    }

    public func updateCheckoutModel(token: PXToken) {
        self.paymentData.updatePaymentDataWith(token: token)
    }

    public func updateCheckoutModel(paymentMethodOptions: [PaymentMethodOption]) {
        if self.rootPaymentMethodOptions != nil {
            self.rootPaymentMethodOptions!.insert(contentsOf: paymentMethodOptions, at: 0)
        } else {
            self.rootPaymentMethodOptions = paymentMethodOptions
        }
        self.paymentMethodOptions = self.rootPaymentMethodOptions
    }

    func updateCheckoutModel(paymentData: PXPaymentData) {
        self.paymentData = paymentData
        if paymentData.getPaymentMethod() == nil {
            prepareForNewSelection()
            self.initWithPaymentData = false
        } else {
            self.readyToPay = true
        }
    }

    public func updateCheckoutModel(payment: PXPayment) {
        self.payment = payment
        self.paymentResult = PaymentResult(payment: self.payment!, paymentData: self.paymentData)
    }

    public func isCheckoutComplete() -> Bool {
        return checkoutComplete
    }

    public func setIsCheckoutComplete(isCheckoutComplete: Bool) {
        self.checkoutComplete = isCheckoutComplete
    }

    internal func findAndCompletePaymentMethodFor(paymentMethodId: String) {
        if paymentMethodId == PXPaymentTypes.ACCOUNT_MONEY.rawValue {
            self.paymentData.updatePaymentDataWith(paymentMethod: Utils.findPaymentMethod(self.availablePaymentMethods!, paymentMethodId: paymentMethodId))
        } else {
            let cardInformation = (self.paymentOptionSelected as! PXCardInformation)
            let paymentMethod = Utils.findPaymentMethod(self.availablePaymentMethods!, paymentMethodId: cardInformation.getPaymentMethodId())
            cardInformation.setupPaymentMethodSettings(paymentMethod.settings)
            cardInformation.setupPaymentMethod(paymentMethod)
            self.paymentData.updatePaymentDataWith(paymentMethod: cardInformation.getPaymentMethod())
            self.paymentData.updatePaymentDataWith(issuer: cardInformation.getIssuer())
        }
    }

    func hasCustomPaymentOptions() -> Bool {
        return !Array.isNullOrEmpty(self.customPaymentOptions)
    }

    internal func handleCustomerPaymentMethod() {
        if self.paymentOptionSelected!.getId() == PXPaymentTypes.ACCOUNT_MONEY.rawValue {
            self.paymentData.updatePaymentDataWith(paymentMethod: Utils.findPaymentMethod(self.availablePaymentMethods!, paymentMethodId: paymentOptionSelected!.getId()))
        } else {
            // Se necesita completar información faltante de settings y pm para custom payment options
            guard let cardInformation = self.paymentOptionSelected as? PXCardInformation else {
                fatalError("Cannot convert paymentOptionSelected to CardInformation")
            }
            let paymentMethod = Utils.findPaymentMethod(self.availablePaymentMethods!, paymentMethodId: cardInformation.getPaymentMethodId())
            cardInformation.setupPaymentMethodSettings(paymentMethod.settings)
            cardInformation.setupPaymentMethod(paymentMethod)
            self.paymentData.updatePaymentDataWith(paymentMethod: cardInformation.getPaymentMethod())
        }
    }

    func entityTypesFinder(inDict: NSDictionary, forKey: String) -> [EntityType]? {
        if let siteETsDictionary = inDict.value(forKey: forKey) as? NSDictionary {
            let entityTypesKeys = siteETsDictionary.allKeys
            var entityTypes = [EntityType]()

            for ET in entityTypesKeys {
                let entityType = EntityType()
                if let etKey = ET as? String, let etValue = siteETsDictionary.value(forKey: etKey) as? String {
                    entityType.entityTypeId = etKey
                    entityType.name = etValue.localized
                    entityTypes.append(entityType)
                }
            }

            return entityTypes
        }

        return nil
    }

    func getEntityTypes() -> [EntityType] {
        let path = ResourceManager.shared.getBundle()!.path(forResource: "EntityTypes", ofType: "plist")
        let dictET = NSDictionary(contentsOfFile: path!)
        let site = SiteManager.shared.getSiteId()

        if let siteETs = entityTypesFinder(inDict: dictET!, forKey: site) {
            return siteETs
        } else {
            let siteETs = entityTypesFinder(inDict: dictET!, forKey: "default")
            return siteETs!
        }
    }

    func errorInputs(error: MPSDKError, errorCallback: (() -> Void)?) {
        MercadoPagoCheckoutViewModel.error = error
        self.errorCallback = errorCallback
    }

    func saveOrDeleteESC() -> Bool {
        guard let token = paymentData.getToken() else {
            return false
        }
        var isApprovedPayment: Bool = true
        if self.paymentResult != nil {
            isApprovedPayment = self.paymentResult!.isApproved()
        } else if self.businessResult != nil {
            isApprovedPayment = self.businessResult!.isApproved()
        } else {
            return false
        }
        if token.hasCardId() {
            if isApprovedPayment && token.hasESC() {
                return mpESCManager.saveESC(cardId: token.cardId, esc: token.esc!)
            } else {
                mpESCManager.deleteESC(cardId: token.cardId)
                return false
            }
        }
        return false
    }

    func populateCheckoutStore() {
        PXCheckoutStore.sharedInstance.paymentData = self.paymentData
        PXCheckoutStore.sharedInstance.checkoutPreference = self.checkoutPreference
    }

    func isPreferenceLoaded() -> Bool {
        return !String.isNullOrEmpty(self.checkoutPreference.id)
    }

    func getResult() -> PXResult? {
        if let ourPayment = payment {
            return ourPayment
        } else {
            return getGenericPayment()
        }
    }

    func getGenericPayment() -> PXGenericPayment? {
        if let paymentResponse = paymentResult {
            return PXGenericPayment(status: paymentResponse.status, statusDetail: paymentResponse.statusDetail, paymentId: paymentResponse.paymentId)
        } else if let businessResultResponse = businessResult {
            return PXGenericPayment(status: businessResultResponse.paymentStatus, statusDetail: businessResultResponse.paymentStatusDetail, paymentId: businessResultResponse.getReceiptId())
        }
        return nil
    }

    func getOurPayment() -> PXPayment? {
        return payment
    }
}

extension MercadoPagoCheckoutViewModel {
    func resetGroupSelection() {
        self.paymentOptionSelected = nil
        guard let search = self.search else {
            return
        }
        self.updateCheckoutModel(paymentMethodSearch: search)
    }

    func resetInFormationOnNewPaymentMethodOptionSelected() {
        resetInformation()
        hookService.resetHooksToShow()
    }

    func resetInformation() {
        self.paymentData.clearCollectedData()
        self.cardToken = nil
        self.entityTypes = nil
        self.financialInstitutions = nil
        cleanPayerCostSearch()
        cleanIssuerSearch()
        cleanIdentificationTypesSearch()
        resetPaymentMethodConfigPlugin()
    }

    func cleanPayerCostSearch() {
        self.payerCosts = nil
    }

    func cleanIssuerSearch() {
        self.issuers = nil
    }

    func cleanIdentificationTypesSearch() {
        self.identificationTypes = nil
    }

    func cleanPaymentResult() {
        self.payment = nil
        self.paymentResult = nil
        self.readyToPay = false
        self.setIsCheckoutComplete(isCheckoutComplete: false)
        self.paymentFlow?.cleanPayment()
    }

    func prepareForClone() {
        self.setIsCheckoutComplete(isCheckoutComplete: false)
        self.cleanPaymentResult()
        self.wentBackFrom(hook: .BEFORE_PAYMENT)
    }

    func prepareForNewSelection() {
        self.setIsCheckoutComplete(isCheckoutComplete: false)
        self.cleanPaymentResult()
        self.resetInformation()
        self.resetGroupSelection()
        self.rootVC = true
        hookService.resetHooksToShow()
    }

    func prepareForInvalidPaymentWithESC() {
        if self.paymentData.isComplete() {
            readyToPay = true
            self.savedESCCardToken = PXSavedESCCardToken(cardId: self.paymentData.getToken()!.cardId, esc: nil, requireESC: advancedConfig.escEnabled)
            mpESCManager.deleteESC(cardId: self.paymentData.getToken()!.cardId)
        }
        self.paymentData.cleanToken()
    }

    static internal func clearEnviroment() {
        MercadoPagoCheckoutViewModel.error = nil
    }
}

// MARK: Advanced Config
extension MercadoPagoCheckoutViewModel {
    func setAdvancedConfiguration(advancedConfig: PXAdvancedConfiguration) {
        self.advancedConfig = advancedConfig
        self.mpESCManager = MercadoPagoESCImplementation(enabled: advancedConfig.escEnabled)
    }

    func getAdvancedConfiguration() -> PXAdvancedConfiguration {
        return advancedConfig
    }
}

// MARK: Payment Flow
extension MercadoPagoCheckoutViewModel {
    func createPaymentFlow(paymentErrorHandler: PXPaymentErrorHandlerProtocol) -> PXPaymentFlow {
        guard let paymentFlow = paymentFlow else {
            let paymentFlow = PXPaymentFlow(paymentPlugin: paymentPlugin, mercadoPagoServicesAdapter: mercadoPagoServicesAdapter, paymentErrorHandler: paymentErrorHandler, navigationHandler: pxNavigationHandler, paymentData: paymentData, checkoutPreference: checkoutPreference)
            self.paymentFlow = paymentFlow
            return paymentFlow
        }
        paymentFlow.model.paymentData = paymentData
        paymentFlow.model.checkoutPreference = checkoutPreference
        return paymentFlow
    }
}
