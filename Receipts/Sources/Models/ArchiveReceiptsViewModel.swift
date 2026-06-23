//
//  ArchiveReceiptsViewModel.swift
//
//  Copyright © 2026 snabble. All rights reserved.
//

import Foundation
import Observation
import SnabbleCore

@Observable
@MainActor
final class ArchiveReceiptsViewModel {

    enum State {
        case idle
        case archiving(ArchiveProgress)
        case done(URL)
        case failed(Error)
    }

    var state: State = .idle

    @ObservationIgnored private var archiveTask: Task<Void, Never>?

    func startArchive(orders: [Order]) {
        archiveTask?.cancel()
        archiveTask = Task {
            do {
                let url = try await OrderArchiveManager.createArchive(from: orders) { [weak self] progress in
                    self?.state = .archiving(progress)
                }
                state = .done(url)
            } catch is CancellationError {
                state = .idle
            } catch {
                state = .failed(error)
            }
        }
    }

    func cancel() {
        archiveTask?.cancel()
    }

    deinit {
        archiveTask?.cancel()
    }
}
