//
//  GatekeeperCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import SnabbleCore
import SwiftUI
import Combine
import SnabbleAssetProviding

public protocol GatekeeperProviding: AnyObject {
    /// Providing an optional `UIViewController` for the given `GatekeeperViewModel`
    /// - Parameter viewModel: The viewModel describing the current `GatekeeperViewModel`
    /// - Parameter domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: The custom view controller for the specified viewModel or `nil`
    func gatekeeper(viewModel: GatekeeperViewModel, domain: Any?) -> UIViewController?
}

public enum Gatekeeper {
    /// Reference to the implementation of the `GatekeeperProviding` implementation
    public static weak var provider: GatekeeperProviding?
 
    /// Reference to the current domain
    public static var domain: Any?
    
    // MARK: - Color
    public static func gatekeeper(viewModel: GatekeeperViewModel, domain: Any? = domain) -> UIViewController? {
        provider?.gatekeeper(viewModel: viewModel, domain: domain)
    }
}

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
        if [.pending].contains(process.paymentState) {
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
            .foregroundColor(Color.projectPrimary())
            .offset(y: (y - (offset * 5)))
            .onAppear {
                withAnimation(animation) {
                    offset = maxY
                }
            }
    }
}

struct GatekeeperView: View {
    @ObservedObject var model: GatekeeperViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var disableButton: Bool = false
    
    @ViewBuilder
    var content: some View {
        VStack(spacing: 8) {
            if let uiImage = model.headerImage {
                SwiftUI.Image(uiImage: uiImage)
                    .padding([.top, .bottom], 20)
            } else {
                SwiftUI.Image(systemName: "platter.filled.bottom.and.arrow.down.iphone")
                    .font(.system(size: 152))
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
                disableButton = true
                model.checkModel.cancelPayment()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(keyed: Asset.localizedString(forKey: "Snabble.cancel"))
                    .fontWeight(.bold)
                    .foregroundColor(Color.projectPrimary())
            }
            .disabled(disableButton)
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
        title = Asset.localizedString(forKey: "Snabble.Payment.transferCart")
    }
}
