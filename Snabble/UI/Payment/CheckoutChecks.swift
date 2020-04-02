//
//  CheckoutChecks.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

public extension Notification.Name {
    static let snabbleShowAgeEntry = Notification.Name("snabbleShowAgeEntry.")
}

struct CheckoutChecks {

    private let process: CheckoutProcess

    init(_ process: CheckoutProcess) {
        self.process = process
    }

    // handle all checks required by the process, and return a Bool indicating whether the process can continue
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

    private func performCheck(_ check: CheckoutCheck) -> Bool {
        guard check.type == .minAge else {
            return false
        }

        switch check.state {
        case .pending:
            let alert = UIAlertController(title: "Snabble.ageVerification.pending.title".localized(),
                                          message: "Snabble.ageVerification.pending.message".localized(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
                if SnabbleUI.implicitNavigation {
                    let germanIdCard = GermanIdCardViewController()
                    let top = UIApplication.topViewController()
                    top?.navigationController?.pushViewController(germanIdCard, animated: true)
                } else {
                    NotificationCenter.default.post(name: .snabbleShowAgeEntry, object: nil)
                }
            })
            alert.addAction(UIAlertAction(title: "Snabble.Cancel".localized(), style: .cancel, handler: nil))

            let topViewController = UIApplication.topViewController()
            topViewController?.present(alert, animated: true)
            return true
        case .failed:
            let alert = UIAlertController(title: "Snabble.ageVerification.failed.title".localized(),
                                          message: "Snabble.ageVerification.failed.message".localized(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .cancel, handler: nil))

            let topViewController = UIApplication.topViewController()
            topViewController?.present(alert, animated: true)
            return true
        case .successful, .unknown:
            return false
        }
    }

}
