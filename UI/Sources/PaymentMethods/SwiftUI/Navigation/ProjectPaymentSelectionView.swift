//
//  ProjectPaymentSelectionView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

/// SwiftUI equivalent of PaymentMethodAddViewController
/// Shows all projects/brands to select where to add payment methods
public struct ProjectPaymentSelectionView: View {
    @State private var manager: PaymentMethodListManager
    @State private var entries: [PaymentMethodListManager.ProjectEntry] = []
    @State private var selectedEntry: PaymentMethodListManager.ProjectEntry?
    @State private var showingAddSheet = false
    @State private var selectedMethod: RawPaymentMethod?

    private weak var analyticsDelegate: AnalyticsDelegate?
    private let brandId: Identifier<Brand>?

    // For brand-specific view (drill-down from multi-project view)
    public init(brandId: Identifier<Brand>, analyticsDelegate: AnalyticsDelegate? = nil) {
        self.brandId = brandId
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager(brandId: brandId))
    }

    // For multi-project view (entry point)
    public init(analyticsDelegate: AnalyticsDelegate? = nil) {
        self.brandId = nil
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager())
    }

    public var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink(value: entry) {
                    ProjectPaymentEntryRow(entry: entry)
                }
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PaymentMethodListManager.ProjectEntry.self) { entry in
            destinationView(for: entry)
        }
        .sheet(isPresented: $showingAddSheet) {
            if let entry = selectedEntry {
                PaymentMethodAddSheet(
                    projectId: entry.projectId,
                    analyticsDelegate: analyticsDelegate
                ) { method in
                    guard method.isAddingAllowed else {
                        return
                    }

                    showingAddSheet = false

                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        selectedMethod = method
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .navigationDestination(item: $selectedMethod) { method in
            if let entry = selectedEntry {
                method.addView(projectId: entry.projectId, analyticsDelegate: analyticsDelegate)
            }
        }
        .task {
            loadEntries()
            analyticsDelegate?.track(.viewPaymentMethodList)
        }
        .onAppear {
            loadEntries()
        }
    }

    @ViewBuilder
    private func destinationView(for entry: PaymentMethodListManager.ProjectEntry) -> some View {
        if let entryBrandId = entry.brandId, brandId == nil {
            // Multi-brand mode: drill down to projects in this brand
            ProjectPaymentSelectionView(brandId: entryBrandId, analyticsDelegate: analyticsDelegate)
        } else if entry.count == 0 {
            // No payment methods yet, show add sheet
            EmptyView()
                .onAppear {
                    selectedEntry = entry
                    showingAddSheet = true
                }
        } else {
            // Show payment methods list for this specific project
            PaymentMethodListView(projectId: entry.projectId, analyticsDelegate: analyticsDelegate)
        }
    }

    private func loadEntries() {
        if let brandId {
            entries = manager.projectEntries(for: brandId)
        } else {
            entries = manager.allProjectEntries()
        }
    }
}

#Preview("Multi-Project") {
    NavigationStack {
        ProjectPaymentSelectionView()
    }
}

#Preview("Single Brand") {
    NavigationStack {
        ProjectPaymentSelectionView(brandId: Identifier<Brand>(rawValue: "test-brand"))
    }
}
