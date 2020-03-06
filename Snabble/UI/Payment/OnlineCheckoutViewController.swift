//
//  OnlineCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public final class OnlineCheckoutViewController: BaseCheckoutViewController {
    override public init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        super.init(process, cart, delegate)

        delegate.track(.viewOnlineCheckout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var viewEvent: AnalyticsEvent {
        return .viewOnlineCheckout
    }

    override public func qrCodeContent(_ process: CheckoutProcess, _ id: String) -> String {
        return process.paymentInformation?.qrCodeContent ?? id
    }

    override var waitForEvents: [PaymentEvent] {
        return [.approval, .paymentSuccess]
    }

    override var autoApproved: Bool {
        return self.process.paymentApproval == true && self.process.supervisorApproval == true
    }
}
