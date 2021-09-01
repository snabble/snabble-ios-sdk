//
//  OriginPoller.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

extension Notification.Name {
    public static let snabbleOriginCandidateReceived = Notification.Name("snabbleOriginCandidateReceived")
}

final class OriginPoller {
    static let shared = OriginPoller()

    private var project: Project?
    private weak var timer: Timer?
    private var candidates = Set<String>()

    private init() {}

    func startPolling(_ project: Project, _ url: String) {
        let allowStart = self.project == nil && !self.candidates.contains(url)
        assert(allowStart, "OriginPoller for \(url) already running")
        guard allowStart else {
            return
        }

        self.project = project
        self.checkCandidate(url)
    }

    private func stopPolling() {
        self.timer?.invalidate()
        self.project = nil
    }

    private func checkCandidate(_ url: String) {
        self.project?.request(.get, url, timeout: 2) { request in
            guard let request = request else {
                return self.stopPolling()
            }

            self.project?.perform(request) { (result: Result<OriginCandidate, SnabbleError>) in
                var continuePolling = true
                switch result {
                case .failure(let error):
                    Log.error("error getting originCandidate: \(error)")
                    if case .httpError(let statusCode) = error, statusCode == 404 {
                        return self.stopPolling()
                    }
                case .success(let candidate):
                    let valid = candidate.isValid
                    if valid {
                        self.candidates.insert(url)
                        let nc = NotificationCenter.default
                        nc.post(name: .snabbleOriginCandidateReceived, object: nil, userInfo: [ "candidate": candidate ])
                    }
                    continuePolling = !valid
                }

                if continuePolling {
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.checkCandidate(url)
                    }
                } else {
                    self.stopPolling()
                }
            }
        }
    }
}
