//
//  PaymentMethodListView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding

// MARK: - Payment Method List View

public struct PaymentMethodListView: View {
    @State private var manager: PaymentMethodListManager

    private weak var analyticsDelegate: AnalyticsDelegate?

    @State private var showingAddSheet = false
    @State private var selectedMethod: RawPaymentMethod?

    public init(projectId: Identifier<SnabbleCore.Project>?, analyticsDelegate: AnalyticsDelegate? = nil) {
        _manager = State(wrappedValue: PaymentMethodListManager(projectId: projectId))
        self.analyticsDelegate = analyticsDelegate
    }

    public var body: some View {
        Group {
            if manager.isEmpty {
                PaymentListEmptyView()
            } else {
                PaymentListItemsView(manager: manager, analyticsDelegate: analyticsDelegate)
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            if let projectId = manager.projectId {
                PaymentMethodAddSheet(
                    projectId: projectId,
                    analyticsDelegate: analyticsDelegate
                ) { method in
                    // Check if adding is allowed
                    guard method.isAddingAllowed else {
                        return
                    }

                    // Close sheet first
                    showingAddSheet = false

                    // Then navigate to add view
                    Task { @MainActor in
                        // Small delay to ensure sheet dismissal animation completes
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        selectedMethod = method
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .navigationDestination(item: $selectedMethod) { method in
            if let projectId = manager.projectId {
                method.addView(projectId: projectId, analyticsDelegate: analyticsDelegate)
            }
        }
        .task {
            manager.loadPayments()
            analyticsDelegate?.track(.viewPaymentMethodList)

            if manager.isEmpty, manager.projectId != nil {
                // Auto-show add sheet if no payments exist
                showingAddSheet = true
            }
        }
        .onAppear {
            // Reload payments when returning from add view
            manager.loadPayments()

            // Reset navigation state when returning to list
            selectedMethod = nil
        }
        .onChange(of: selectedMethod) { oldValue, newValue in
            // When returning from add view (selectedMethod becomes nil)
            if oldValue != nil && newValue == nil {
                manager.loadPayments()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentMethodAdded)) { _ in
            // Payment method was successfully added from UIKit ViewController
            // Reset navigation state and reload payments
            selectedMethod = nil
            manager.loadPayments()
        }
    }
}

#Preview {
    NavigationStack {
        PaymentMethodListView(projectId: Identifier<SnabbleCore.Project>(rawValue: "test"))
    }
}
