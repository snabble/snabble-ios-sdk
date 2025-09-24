//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

final class SupervisorViewModel: BaseCheckViewModel {
    override func updateCodeImage() {
        self.codeImage = PDF417.generate(for: self.checkModel.codeContent, scale: 2)
    }
    // supervisors are only concerned with checks: if there are failed checks, bail out,
    // and if all checks pass, finalize the checkout
    override func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }
        return .continuePolling
    }
}

struct SupervisorView: View {
    @State var model: SupervisorViewModel

    @State private var disableButton: Bool = false

    @ViewBuilder
    var content: some View {
        Group {
            Spacer()
            VStack(spacing: 10) {
                if let uiImage = model.headerImage {
                    SwiftUI.Image(uiImage: uiImage)
                        .padding([.bottom], 20)
                }
                Text(Asset.localizedString(forKey: "Snabble.Payment.Online.message"))
            }
            Spacer()
            VStack(spacing: 10) {
                if let codeImage = model.codeImage {
                    SwiftUI.Image(uiImage: codeImage)
                }
                Text(model.idString)
                    .font(.footnote)
            }
            Spacer()
            Button(action: {
                disableButton = true
                model.checkModel.cancelPayment()
            }) {
                Text(keyed: Asset.localizedString(forKey: "Snabble.cancel"))
                    .fontWeight(.bold)
                    .foregroundColor(Color.projectPrimary())
            }
            .frame(alignment: .bottom)
            .disabled(disableButton)
        }
    }
    var body: some View {
        content
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

final class SupervisorCheckViewController: BaseCheckViewController<SupervisorView> {
    convenience init(model: SupervisorViewModel) {
        self.init(model: model, rootView: SupervisorView(model: model))
    }
}
