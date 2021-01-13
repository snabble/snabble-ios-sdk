//
//  ExitTokenPoller.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

final class ExitTokenPoller {
    static let shared = ExitTokenPoller()

    private var processTimer: Timer?
    private var sessionTask: URLSessionTask?
    private var project: Project?
    private var process: CheckoutProcess?

    private var completion: ((CheckoutProcess, [String: Any]?) -> Void)?

    private init() {}

    func startPolling(_ project: Project, _ process: CheckoutProcess, completion: @escaping (CheckoutProcess, [String: Any]?) -> Void) {
        let allowStart = self.process == nil && self.project == nil
        assert(allowStart, "ExitPoller already running")
        guard allowStart else {
            return
        }

        self.project = project
        self.process = process
        self.completion = completion

        self.startTimer()
    }

    // MARK: - polling timer
    private func startTimer() {
        guard
            let process = self.process,
            let project = self.project
        else {
            return
        }

        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            process.update(project,
                           taskCreated: { self.sessionTask = $0 },
                           completion: { self.update($0) })
        }
    }

    private func stopPolling() {
        self.processTimer?.invalidate()
        self.processTimer = nil

        self.sessionTask?.cancel()
        self.sessionTask = nil

        self.project = nil
        self.process = nil
        self.completion = nil
    }

    // MARK: - process updates
    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        var continuePolling = true
        switch result.result {
        case .success(let process):
            continuePolling = process.exitToken?.value == nil
            if !continuePolling {
                self.completion?(process, result.rawJson)
                self.completion = nil
            }
        case .failure(let error):
            Log.error(String(describing: error))
        }

        if continuePolling {
            self.startTimer()
        } else {
            self.stopPolling()
        }
    }
}
