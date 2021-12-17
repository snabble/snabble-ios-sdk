//
//  CheckoutChecks.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

struct CheckoutChecks {
    private let process: CheckoutProcess

    init(_ process: CheckoutProcess) {
        self.process = process
    }

    // check if any of the checks failed, return true if so
    func failed() -> Bool {
        let failed = self.process.checks.firstIndex { $0.state == .failed }
        return failed != nil
    }

    // handle all checks required by the process, and return a Bool indicating whether the process should be stopped
    func handleChecks() -> Bool {
        if self.process.checks.isEmpty {
            return false
        }

        var stopProcess = false
        for check in process.checks {
            stopProcess = stopProcess || self.performCheck(check)
        }
        return stopProcess
    }

    private func performCheck(_ check: CheckoutProcess.Check) -> Bool {
        return false
//        switch check.type {
//        case .unknown: return false
//        case .minAge: return self.performAgeCheck(check)
//        }
    }

    private func performAgeCheck(_ check: CheckoutProcess.Check) -> Bool {
        return false
//        switch check.performedBy {
//        case .app:
//            // DIY
//            return performAppAgeCheck(check)
//        case .none, .unknown, .backend, .payment, .supervisor:
//            // check for failure, else continue waiting
//            switch check.state {
//            case .failed:
//                return true
//            case .pending, .successful, .postponed, .unknown:
//                return false
//            }
//        }
    }

//    private func performAppAgeCheck(_ check: CheckoutCheck) -> Bool {
//        switch check.state {
//        case .pending:
//            return true
//        case .failed:
//            let alert = UIAlertController(title: L10n.Snabble.AgeVerification.Failed.title,
//                                          message: L10n.Snabble.AgeVerification.Failed.message,
//                                          preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .cancel, handler: nil))
//
//            let topViewController = UIApplication.topViewController()
//            topViewController?.present(alert, animated: true)
//            return true
//        case .successful, .postponed, .unknown:
//            return false
//        }
//    }

}
