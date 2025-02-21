//
//  PaymentMethodManager.swift
//
//
//  Created by Uwe Tilemann on 10.06.24.
//

import UIKit
import SDCAlertView

import SnabbleCore
import SnabbleAssetProviding

extension PaymentPovider {
    public var icon: UIImage? {
        methodDetail?.icon ?? method.icon
    }
}

public protocol PaymentMethodManagerDelegate: AnyObject {
    func paymentMethodManager(didSelectItem: PaymentMethodItem)
    func paymentMethodManager(didSelectPayment: Payment?)
}

public final class PaymentMethodManager: ObservableObject {
    @Published public var selectedPayment: Payment?
    @Published public var hasMethodsToSelect: Bool = true
    
    let paymentConsumer: PaymentConsumer?
    
    var details: [PaymentMethodDetail]
    
    let project: Project
    
    public weak var delegate: PaymentMethodManagerDelegate?
    
    public init(project: Project, paymentConsumer: PaymentConsumer?, delegate: PaymentMethodManagerDelegate? = nil) {
        self.project = project
        self.paymentConsumer = paymentConsumer
        self.delegate = delegate
        
        self.details = PaymentMethodDetails.read().filter { detail in
            SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
        }
        self.updateSelectionVisibility()
        self.setDefaultPaymentMethod()
        
        let nc = NotificationCenter.default
        _ = nc.addObserver(forName: .snabblePaymentMethodAdded, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let detail = notification.userInfo?["detail"] as? PaymentMethodDetail else {
                return
            }
            self?.details = PaymentMethodDetails.read().filter { detail in
                SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
            }
            self?.selectMethodIfValid(detail)
        }
        
        _ = nc.addObserver(forName: .snabblePaymentMethodDeleted, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.details = PaymentMethodDetails.read().filter { detail in
                SnabbleCI.project.paymentMethods.available.contains { $0 == detail.rawMethod }
            }
            self?.selectMethodIfValid()
        }
    }
    
    // hide selection if
    // - the project only has one method,
    // - we have no payment method data for it,
    // - and none is needed for this method
    private var isHidden: Bool {
        return project.paymentMethods.available.count < 2 &&
        details.isEmpty &&
        project.paymentMethods.available.first?.dataRequired == false
    }
    
    func updateSelectionVisibility() {
        
        hasMethodsToSelect = !isHidden
        
        if let selectedMethod = selectedPayment?.method {
            if selectedMethod.dataRequired {
                if let selectedDetail = selectedPayment?.detail {
                    let method = details.first { $0 == selectedDetail }
                    if method != nil {
                        assert(method?.rawMethod == selectedMethod)
                        return
                    }
                }
            } else {
                return
            }
        }
        
        // no method selected, or method no longer valid: select a new default
        self.setDefaultPaymentMethod()
    }

    private func selectMethodIfValid(_ detail: PaymentMethodDetail? = nil) {
        if let detail = detail {
            // method was added, check if we can use it
            let inCart = self.paymentConsumer?.paymentMethods?.contains { $0.method == detail.rawMethod }
            if inCart == true {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            } else if self.project.paymentMethodDetails.contains(detail), detail != self.selectedPayment?.detail {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            }
        } else {
            // method was deleted, check if it was the selected one
            if let selectedDetail = self.selectedPayment?.detail {
                self.selectedPayment = nil
                let allMethods = PaymentMethodDetails.read()
                if allMethods.firstIndex(of: selectedDetail) == nil {
                    self.setDefaultPaymentMethod()
                }
            }
        }
    }
    
    func updateAvailablePaymentMethods() {
        if !project.paymentMethods.available.contains(where: { $0 == selectedPayment?.method }) {
            self.setDefaultPaymentMethod()
        } else {
            self.setSelectedPayment(self.selectedPayment?.method, detail: self.selectedPayment?.detail)
        }
    }
    
    public func update() {
        updateAvailablePaymentMethods()
        updateSelectionVisibility()
    }
    
    private func setSelectedPayment(_ method: RawPaymentMethod?, detail: PaymentMethodDetail?) {
        if let detail {
            self.selectedPayment = Payment(detail: detail)
        } else if let method {
            self.selectedPayment = Payment(method: method)
        } else {
            self.selectedPayment = nil
        }
        delegate?.paymentMethodManager(didSelectPayment: self.selectedPayment)
    }

    private func setDefaultPaymentMethod() {
        self.selectedPayment = project.preferredPayment
    }
    
    public func setSelectedPaymentItem(_ item: PaymentMethodItem) {
        guard item.selectable else { return }
        
        setSelectedPayment(item.method, detail: item.methodDetail)

        delegate?.paymentMethodManager(didSelectItem: item)
    }
}

public protocol SheetProviding {
    typealias DismissHandler = () -> Void
    func sheetController(_ onDismiss: DismissHandler?) -> UIViewController
}

public protocol AlertProviding {
    typealias DismissHandler = (UIAlertAction) -> Void
    func alertController(_ onDismiss: DismissHandler?) -> UIAlertController
}

extension PaymentMethodManager: SheetProviding {
    public func sheetController(_ onDismiss: DismissHandler? = { }) -> UIViewController {
        let title = Asset.localizedString(forKey: "Snabble.Shoppingcart.howToPay")
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.outsideTapHandler = onDismiss
        sheet.visualStyle = .snabbleActionSheet
        
        let actions = project.paymentActions(for: paymentConsumer)

        let isAnyActive = actions.contains { $0.active == true && $0.method.offline == false }

        // add an action for each method
        for action in actions {
            let alertAction = AlertAction(attributedTitle: action.title, style: .normal) { [self] _ in
                if action.selectable {
                    setSelectedPaymentItem(action.item)
                    onDismiss?()
                }
            }

            let icon = isAnyActive && !(action.active || action.methodDetail != nil) ? action.icon?.grayscale() : action.icon
            alertAction.imageView.image = icon
            alertAction.imageView.setContentCompressionResistancePriority(.required, for: .vertical)

            sheet.addAction(alertAction)
        }

        // add the cancel action
        sheet.addAction(AlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .preferred) { _ in
            onDismiss?()
        })
        
        return sheet
    }
}
