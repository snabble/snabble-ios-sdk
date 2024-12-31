//
//  VoucherAlertViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 30.12.24.
//

import SwiftUI
import UIKit
import Combine

import SnabbleCore
import SnabbleAssetProviding

final class VoucherAlertViewController: UIHostingController<VoucherAlertView>  {
    var actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(vouchers: [CartVoucher], shoppingCart: ShoppingCart) {
        let rootView = VoucherAlertView(vouchers: vouchers, shoppingCart: shoppingCart, publisher: actionPublisher)
        super.init(rootView: rootView)
    }
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.actionPublisher
            .sink { [weak self] info in
                self?.stepAction(userInfo: info)
            }
            .store(in: &cancellables)
    }
    @objc func stepAction(userInfo: [String: Any]?) {
        if let userInfo = userInfo {
            if let action = userInfo["action"] as? String, action == "done" {
                navigationController?.popViewController(animated: true)
            }
        }
    }
}

struct VoucherAlertView: View {
    var vouchers: [CartVoucher]
    var shoppingCart: ShoppingCart
    var publisher: PassthroughSubject<[String: Any]?, Never>
    
    @State private var voucherString: String = ""
    
    var body: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text(keyed: "Snabble.ShoppingCart.DepositVoucher.RedemptionFailed.title")
                    .font(.headline)
                Text(voucherString)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(10)
            }
            Button(role: .destructive, action: {
                removeVouchers()
                publisher.send(["action": "done"])
            }) {
                Text(keyed: "Snabble.ShoppingCart.DepositVoucher.RedemptionFailed.button")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .task {
            voucherString = Asset.localizedString(
                forKey: "Snabble.ShoppingCart.DepositVoucher.RedemptionFailed.message" + (vouchers.count == 1 ? ".singular" : ".plural"),
                arguments: shoppingCart.vouchersDescription(vouchers)
            )
            .replacingOccurrences(of: "\\n", with: "\n")
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.ShoppingCart.DepositVoucher.RedemptionFailed.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func removeVouchers() {
        for voucher in vouchers {
            shoppingCart.removeVoucher(voucher.voucher)
        }
    }
}
