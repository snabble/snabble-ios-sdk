//
//  GatekeeperCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import SnabbleCore
import SwiftUI
import Combine

public final class GatekeeperViewModel: BaseCheckViewModel {
    
    override func updateCodeImage() {
        self.codeImage = QRCode.generate(for: self.checkModel.codeContent, scale: 5)
    }

    // gatekeeper decision depends on the process' checks as well as the payment and fulfillment status
    override func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        // this is necessary because currently the paymentState stays at `.pending`
        // when allocation failures happen
        if process.fulfillmentsAllocationFailed() > 0 {
            return .finalizeCheckout
        }

        // gatekeepers also have to wait until the payment moves to e.g. `.transferred`
        // or `.processing`, e.g. for payments via the physical card readers
        if process.paymentState == .pending {
            return .continuePolling
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }
        return .continuePolling
    }
}


struct UpArrow: View {
    var y: CGFloat = 0
    var maxY: CGFloat = 5
    
    let animation: Animation = Animation.easeInOut(duration: 0.8).delay(0.2).repeatForever(autoreverses: true)
    @State var offset: CGFloat = 0.0
    
    var body: some View {
        SwiftUI.Image(systemName: "arrow.up")
            .font(Font(.init(.application, size: 40)))
            .foregroundColor(Color.accent())
            .offset(y: (y - (offset*5)))
            .onAppear {
                withAnimation(animation) {
                    offset = maxY
                }
            }
    }
}

struct GatekeeperView: View {
    @ObservedObject var model: GatekeeperViewModel

    @ViewBuilder
    var content: some View {
        VStack(spacing:8) {
            if let uiImage = model.headerImage {
                SwiftUI.Image(uiImage: uiImage)
                    .padding([.top, .bottom], 20)
            }
            UpArrow()
            if let codeImage = model.codeImage {
                SwiftUI.Image(uiImage: codeImage)
                    .padding([.top], 20)
            }
            Text(model.idString)
                .font(.footnote)
                .padding(.top, 10)
            Spacer()
            Button(action: {
                model.checkModel.cancelPayment()
            }) {
                Text(keyed: Asset.localizedString(forKey: "Snabble.cancel"))
                    .fontWeight(.bold)
                    .foregroundColor(Color.accent())
            }
        }
    }
    var body: some View {
        content
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

final class GatekeeperCheckViewController: BaseCheckViewController<GatekeeperView> {
    convenience init(model: GatekeeperViewModel) {
        self.init(model: model, rootView: GatekeeperView(model: model))
    }
}
