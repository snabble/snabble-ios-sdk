//
//  OriginPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

protocol OriginPollerDelegate: AnyObject {
    func originPoller(_ originPoller: OriginPoller, didReceiveCandidate originCandidate: OriginCandidate)
}

final class OriginPoller: @unchecked Sendable {
    private let project: Project
    private(set) var candidatesURLStrings = Set<String>()

    weak var delegate: OriginPollerDelegate?

    init(project: Project) {
        self.project = project
    }

    private weak var timer: Timer?

    private func urlString(for checkoutProcess: CheckoutProcess) -> String? {
        checkoutProcess.paymentResult?["originCandidateLink"] as? String
    }

    func shouldStart(for checkoutProcess: CheckoutProcess) -> Bool {
        guard let urlString = urlString(for: checkoutProcess) else {
            return false
        }

        guard !candidatesURLStrings.contains(urlString) else {
            return false
        }

        return true
    }

    func start(for checkoutProcess: CheckoutProcess) {
        guard let urlString = urlString(for: checkoutProcess),
              !candidatesURLStrings.contains(urlString) else {
            return
        }
        candidatesURLStrings.insert(urlString)
        checkCandidate(urlString)
    }

    func stop() {
        timer?.invalidate()
        candidatesURLStrings.removeAll()
    }

    private func checkCandidate(_ url: String) {
        project.request(.get, url, timeout: 2) { [self] request in
            guard let request = request else {
                stop()
                return
            }

            project.perform(request) { [self] (result: Result<OriginCandidate, SnabbleError>) in
                var continuePolling = true
                switch result {
                case .failure(let error):
                    Log.error("error getting originCandidate: \(error)")
                    switch error {
                    case .apiError(_, let statusCode):
                        if statusCode == 404 {
                            return stop()
                        }
                    default:
                        break
                    }
                case .success(let candidate):
                    continuePolling = !candidate.isValid
                    delegate?.originPoller(self, didReceiveCandidate: candidate)
                }

                if continuePolling {
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                        self?.checkCandidate(url)
                    }
                } else {
                    stop()
                }
            }
        }
    }
}
