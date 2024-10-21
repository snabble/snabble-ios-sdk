//
//  ActionState.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 28.06.24.
//

import SwiftUI
import OSLog
import Combine
import SnabbleUI
import SnabbleAssetProviding
import SnabbleComponents

/// Represents different types of actions that can be triggered in the application.
public enum ActionType: Equatable {
    /// Nothing to display
    case idle
    /// Shows a full screen `String` message, which will be automatically dismissed after a period of time (like 3 seconds) or if the user tap on the screen
    case toast(Toast)
    /// Shows a `View` full screen, the view needs to dismiss itself
    case dialog(any View)
    /// Shows a `View` full screen, using `.sheet(isPresenting:) {}`
    case sheet(any View)
    /// Shows the given associated `SheetProviding`
    case alertSheet(SheetProviding)
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
        case .idle:
            "idle"
        case .toast:
            "toast"
        case .dialog:
            "dialog"
        case .sheet:
            "sheet"
        case .alertSheet:
            "alertSheet"
        case .alert:
            "alert"
        }
    }
}

/// Represents an action item with a type and domain.
struct ActionItem: Swift.Identifiable, Equatable {
    static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String {
        domain + ":" + type.description
    }
    
    let type: ActionType
    let domain: String
    var isActive: Bool = false
    
    init(type: ActionType, domain: String = "global") {
        self.type = type
        self.domain = domain
    }
}

/// Manages the state and handling of actions within the application.
///
/// The `ActionManager` is a singleton class responsible for managing the different types of actions that can be triggered
/// throughout the application. It publishes action states and provides a mechanism for views to observe and respond to these
/// states.
public final class ActionManager: ObservableObject {
    public static let shared = ActionManager()
    
    let logger = Logger(subsystem: "ScanAndGo", category: "ActionManager")
    public let actionPublisher = PassthroughSubject<ActionType, Never>()
    
    /// The current state of the action being handled.
    /// Updates to this property will trigger corresponding UI changes in subscribed views.
   @Published var actionState: ActionType = .idle {
        didSet {
            logger.debug("handleAction: \(oldValue) -> \(self.actionState)")
        }
    }
    /// The currently active action item.
    /// This property holds the details of the current action, including its type and domain.
    @Published var currentAction: ActionItem?

    /// Indicates whether an action is currently presented.
    /// This property helps in managing the presentation state of different actions.
    @Published var isPresented: Bool = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    public init() {
        actionPublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] action in
                self.actionState = action
            }
            .store(in: &subscriptions)
    }
    private func handleAction(_ newState: ActionType) {
        self.actionState = newState
    }
    
    /// Sends a new action state to be handled.
    /// - Parameter actionState: The new action state to be handled.
    public func send(_ actionState: ActionType) {
        currentAction = ActionItem(type: actionState)
        actionPublisher.send(actionState)
    }
}

/// A view modifier that observes the `ActionManager` and modifies the view based on the current action state.
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
    @State var alertSheetPresented: Bool = false
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
    @ViewBuilder var alertSheetView: some View {
        if case .alertSheet(let sheetProvider) = actionState {
            let sheet = sheetProvider.sheetController { }
            ContainerView(viewController: sheet, isPresented: $alertSheetPresented)
        } else {
            ErrorText(reason: "No alertSheet to be displayed.")
        }
    }
    
    private func handleAction(_ newState: ActionType) {
        actionState = newState
        
        switch newState {
        case .idle:
            toast = nil
            dialogPresented = false
            sheetPresented = false
            alertSheetPresented = false
            alertPresented = false
            
        case .toast(let toast):
            self.toast = toast
        case .dialog:
            dialogPresented = true
        case .sheet:
            sheetPresented = true
        case .alertSheet:
            alertSheetPresented = true
        case .alert:
            alertPresented = true
        }
    }
        
    @ViewBuilder
    public func body(content: Content) -> some View {
        content
            .onReceive(ActionManager.shared.actionPublisher) { actionType in
                handleAction(actionType)
            }
            .toast(item: $toast)
            .onChange(of: toast, { oldValue, newValue in
                resetState(newValue != nil)
            })
            .windowDialog(isPresented: $dialogPresented) {
                dialogView
            }
            .onChange(of: dialogPresented) {
                resetState(dialogPresented)
            }
        
            .windowDialog(isPresented: $sheetPresented) {
                dialogView
            }
            .onChange(of: sheetPresented) {
                resetState(sheetPresented)
            }
        
            .windowDialog(isPresented: $alertSheetPresented) {
                alertSheetView
            }
            .onChange(of: alertSheetPresented) {
                resetState(alertSheetPresented)
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
    /// A view modifier that applies the `ActionModifier` to the view.
    public func actionState() -> some View {
        self.modifier(ActionModifier())
    }
}
