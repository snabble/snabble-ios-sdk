//
//  ArchiveReceiptsViewModel.swift
//
//  Created by Uwe Tilemann on 25.06.26.
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
        archiveTask = Task { [weak self] in
            do {
                let url = try await OrderArchiveManager.createArchive(from: orders) { [weak self] progress in
                    self?.state = .archiving(progress)
                }
                self?.state = .done(url)
            } catch is CancellationError {
                self?.state = .idle
            } catch {
                self?.state = .failed(error)
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
