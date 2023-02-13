//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import SwiftUI
import SnabbleCore

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
    @ObservedObject var model: SupervisorViewModel
    
    var body: some View {
        VStack {
            
        }
    }
}

final class SupervisorCheckViewController: BaseCheckViewController<SupervisorView> {
    convenience init(model: SupervisorViewModel) {
        self.init(model: model, rootView: SupervisorView(model: model))
    }
}
