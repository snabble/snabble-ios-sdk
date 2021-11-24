//
//  OriginPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

final class OriginPoller {
    private let project: Project
    private(set) var candidatesURLStrings = Set<String>()
    private var candidates = Set<OriginCandidate>()

    init(project: Project) {
        self.project = project
    }

    private weak var timer: Timer?

    func validCandidate(for checkoutProcess: CheckoutProcess) -> OriginCandidate? {
        guard let urlString = checkoutProcess.paymentResult?["originCandidateLink"] as? String else {
            return nil
        }
        return candidates.first { candidate in
            guard let href = candidate.links?.`self`.href, href == urlString else {
                return false
            }
            guard candidate.isValid else {
                return false
            }
            return true
        }
    }

    func startPolling(for checkoutProcess: CheckoutProcess) {
        guard let urlString = checkoutProcess.paymentResult?["originCandidateLink"] as? String,
              !candidatesURLStrings.contains(urlString) else {
            return
        }
        candidatesURLStrings.insert(urlString)
        checkCandidate(urlString)
    }

    private func stopPolling() {
        timer?.invalidate()
        candidatesURLStrings.removeAll()
    }

    private func checkCandidate(_ url: String) {
        project.request(.get, url, timeout: 2) { [self] request in
            guard let request = request else {
                stopPolling()
                return
            }

            project.perform(request) { [self] (result: Result<OriginCandidate, SnabbleError>) in
                var continuePolling = true
                switch result {
                case .failure(let error):
                    Log.error("error getting originCandidate: \(error)")
                    if case .httpError(let statusCode) = error, statusCode == 404 {
                        return stopPolling()
                    }
                case .success(let candidate):
                    continuePolling = !candidate.isValid
                    candidates.insert(candidate)
                }

                if continuePolling {
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                        self?.checkCandidate(url)
                    }
                } else {
                    stopPolling()
                }
            }
        }
    }
}
