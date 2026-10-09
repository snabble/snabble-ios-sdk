//
//  SessionsViewModel.swift
//  SnabblePayExample
//

import Foundation
import SnabblePay
import SnabbleLogger

@Observable
@MainActor
final class SessionsViewModel {
    private var snabblePay: SnabblePay {
        return .shared
    }

    var sessions: [Session]?

    func loadSessions() {
        Task {
            do {
                sessions = try await snabblePay.sessions()
                ErrorHandler.shared.error = nil
            } catch let error as SnabblePay.Error {
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Loading Sessions")
            } catch {
                ErrorHandler.shared.error = ErrorInfo(error: .unexpected(error), action: "Loading Sessions")
            }
        }
    }

    func delete(session: Session) {
        Task {
            do {
                let deleted = try await snabblePay.deleteSession(withId: session.id)
                Logger.shared.debug("Session deleted: \(deleted.id)")
                loadSessions()
            } catch let error as SnabblePay.Error {
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Delete Session")
            } catch {
                ErrorHandler.shared.error = ErrorInfo(error: .unexpected(error), action: "Delete Session")
            }
        }
    }
}
