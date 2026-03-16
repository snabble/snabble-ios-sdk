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
    @State private var showingAddSheet = false

    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(projectId: Identifier<SnabbleCore.Project>, analyticsDelegate: AnalyticsDelegate? = nil) {
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
                )
                .presentationDetents([.medium])
            }
        }
        .task {
            manager.loadPayments()
            analyticsDelegate?.track(.viewPaymentMethodList)

            if manager.isEmpty, let projectId = manager.projectId {
                // Auto-show add sheet if no payments exist
                showingAddSheet = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaymentMethodListView(projectId: Identifier<SnabbleCore.Project>(rawValue: "test"))
    }
}
