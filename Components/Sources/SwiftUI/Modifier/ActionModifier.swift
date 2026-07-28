//
//  ActionModifier.swift
//  SnabbleComponents
//
//  Created by Uwe Tilemann on 28.06.24.
//

import SwiftUI
import OSLog

private extension String {
    static func errorString(reason: String) -> String {
        "\(reason)\nThis should not happen! 😳"
    }
}

private struct ErrorText: View {
    let reason: String

    var body: some View {
        Text(String.errorString(reason: reason))
    }
}

/// Represents different types of actions that can be triggered in the application.
public enum ActionType: Equatable, @unchecked Sendable {
    /// Nothing to display
    case idle
    /// Shows a full screen `String` message, which will be automatically dismissed after a period of time (like 3 seconds) or if the user tap on the screen
    case toast(Toast)
    /// Shows a `View` full screen, the view needs to dismiss itself
    case dialog(any View)
    /// Shows a `View` full screen, using `.sheet(isPresenting:) {}`
    case sheet(any View)
    /// Shows the given associated `Alert`
    case alert(Alert)

    public static func == (lhs: ActionType, rhs: ActionType) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.toast(let lhsToast), .toast(let rhsToast)):
            return lhsToast == rhsToast
        default:
            return false
        }
    }
}

extension ActionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle: "idle"
        case .toast: "toast"
        case .dialog: "dialog"
        case .sheet: "sheet"
        case .alert: "alert"
        }
    }
}

/// Represents an action item with a type and domain.
public struct ActionItem: Swift.Identifiable, Equatable {
    public static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        lhs.id == rhs.id
    }

    public var id: String {
        domain + ":" + type.description
    }

    public let type: ActionType
    public let domain: String
    public var isActive: Bool = false

    public init(type: ActionType, domain: String = "global") {
        self.type = type
        self.domain = domain
    }
}

/// Manages the state and handling of actions within the application.
///
/// The `ActionManager` is a singleton class responsible for managing the different types of actions that can be triggered
/// throughout the application. It publishes action states and provides a mechanism for views to observe and respond to these states.
@Observable
public final class ActionManager {
    nonisolated(unsafe) public static let shared = ActionManager()

    let logger = Logger(subsystem: "io.snabble.sdk", category: "ActionManager")

    @ObservationIgnored public private(set) var actionStream: AsyncStream<ActionType>
    @ObservationIgnored private var actionContinuation: AsyncStream<ActionType>.Continuation?

    var actionState: ActionType = .idle {
        didSet {
            logger.debug("handleAction: \(oldValue) -> \(self.actionState)")
        }
    }
    var currentAction: ActionItem?
    var isPresented: Bool = false

    public init() {
        var cont: AsyncStream<ActionType>.Continuation!
        actionStream = AsyncStream { cont = $0 }
        actionContinuation = cont
    }

    deinit {
        actionContinuation?.finish()
    }

    /// Sends a new action state to be handled.
    /// - Parameter actionState: The new action state to be handled.
    public func send(_ actionState: ActionType) {
        currentAction = ActionItem(type: actionState)
        self.actionState = actionState
        actionContinuation?.yield(actionState)
    }
}

/// Observes `ActionManager.shared` and renders the current action as the appropriate UI overlay.
///
/// Apply this modifier once at the root of your view hierarchy.
/// Without it, toasts, dialogs, sheets, and alerts triggered by the `ActionManager` will not appear.
///
/// ```swift
/// RootView()
///     .actionState()
/// ```
public struct ActionModifier: ViewModifier {
    @State var actionState: ActionType = .idle {
        didSet {
            if case .toast(let toast) = actionState {
                self.toast = toast
            }
        }
    }

    @State private var toast: Toast?

    @State var dialogPresented: Bool = false
    @State var sheetPresented: Bool = false
    @State var alertPresented: Bool = false

    @ViewBuilder var dialogView: some View {
        if case .dialog(let view) = actionState {
            AnyView(view)
        } else {
            ErrorText(reason: "No dialogView to be displayed.")
        }
    }

    @ViewBuilder var sheetView: some View {
        if case .sheet(let view) = actionState {
            AnyView(view)
        } else {
            ErrorText(reason: "No sheetView to be displayed.")
        }
    }

    private func handleAction(_ newState: ActionType) {
        actionState = newState

        switch newState {
        case .idle:
            toast = nil
            dialogPresented = false
            sheetPresented = false
            alertPresented = false
        case .toast(let toast):
            self.toast = toast
        case .dialog:
            dialogPresented = true
        case .sheet:
            sheetPresented = true
        case .alert:
            alertPresented = true
        }
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        content
            .task {
                for await actionType in ActionManager.shared.actionStream {
                    handleAction(actionType)
                }
            }
            .toast(item: $toast)
            .onChange(of: toast) { _, newValue in
                resetState(newValue != nil)
            }
            .windowDialog(isPresented: $dialogPresented) {
                dialogView
            }
            .onChange(of: dialogPresented) {
                resetState(dialogPresented)
            }
            .windowDialog(isPresented: $sheetPresented) {
                sheetView
            }
            .onChange(of: sheetPresented) {
                resetState(sheetPresented)
            }
            .alert(isPresented: $alertPresented) {
                if case .alert(let alert) = actionState {
                    alert
                } else {
                    Alert(title: Text(String.errorString(reason: "No alert to be displayed.")))
                }
            }
            .onChange(of: alertPresented) {
                resetState(alertPresented)
            }
    }

    func resetState(_ isPresented: Bool) {
        if !isPresented {
            ActionManager.shared.send(.idle)
        }
    }
}

extension View {
    /// Applies `ActionModifier` to the view.
    ///
    /// Required at the root of any view hierarchy that uses `ActionManager`.
    public func actionState() -> some View {
        modifier(ActionModifier())
    }

    /// Applies `ActionModifier` to the view.
    @available(*, deprecated, renamed: "actionState")
    public func shopperActions() -> some View {
        actionState()
    }
}

/// Backward-compatibility alias.
@available(*, deprecated, renamed: "ActionModifier")
public typealias ShopperActionModifier = ActionModifier
