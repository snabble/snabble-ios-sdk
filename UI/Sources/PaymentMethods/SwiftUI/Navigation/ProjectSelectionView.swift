//
//  ProjectSelectionView.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

/// SwiftUI equivalent of PaymentMethodAddViewController
/// Shows all projects/brands to select where to add payment methods
public struct ProjectSelectionView: View {
    @State private var manager: PaymentMethodListManager
    @State private var entries: [PaymentMethodListManager.ProjectEntry] = []

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
                ProjectEntryRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleEntryTap(entry)
                    }
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadEntries()
            analyticsDelegate?.track(.viewPaymentMethodList)
        }
    }

    // MARK: - Private Methods

    private func loadEntries() {
        if let brandId {
            entries = manager.projectEntries(for: brandId)
        } else {
            entries = manager.allProjectEntries()
        }
    }

    private func handleEntryTap(_ entry: PaymentMethodListManager.ProjectEntry) {
        // If this entry has a brand and we're in the multi-project view,
        // drill down to show projects in that brand
        if let entryBrandId = entry.brandId, brandId == nil {
            // Navigate to brand-specific view
            // This will be handled by NavigationLink in the actual implementation
            return
        }

        // Otherwise, show/add methods for this specific project
        if entry.count == 0 {
            // No methods yet, show add sheet directly
            // This will be handled by the parent view
        } else {
            // Navigate to payment method list for this project
            // This will be handled by NavigationLink in the actual implementation
        }
    }
}

// MARK: - Project Entry Row

struct ProjectEntryRow: View {
    let entry: PaymentMethodListManager.ProjectEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.body)

                if entry.count > 0 {
                    Text("\(entry.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Navigation Wrapper

/// Complete navigation flow for adding payment methods across projects
public struct PaymentMethodProjectNavigationView: View {
    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(analyticsDelegate: AnalyticsDelegate? = nil) {
        self.analyticsDelegate = analyticsDelegate
    }

    public var body: some View {
        NavigationStack {
            ProjectSelectionList(analyticsDelegate: analyticsDelegate)
        }
    }
}

/// Internal view that handles navigation between project selection and payment methods
struct ProjectSelectionList: View {
    @Environment(\.dismiss) private var dismiss

    @State private var manager: PaymentMethodListManager
    @State private var entries: [PaymentMethodListManager.ProjectEntry] = []
    @State private var selectedEntry: PaymentMethodListManager.ProjectEntry?
    @State private var showingAddSheet = false

    weak var analyticsDelegate: AnalyticsDelegate?
    let brandId: Identifier<Brand>?

    init(brandId: Identifier<Brand>? = nil, analyticsDelegate: AnalyticsDelegate? = nil) {
        self.brandId = brandId
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager(brandId: brandId))
    }

    var body: some View {
        List {
            ForEach(entries) { entry in
                if entry.brandId != nil && brandId == nil {
                    // Brand entry - navigate to brand-specific view
                    NavigationLink {
                        ProjectSelectionList(
                            brandId: entry.brandId,
                            analyticsDelegate: analyticsDelegate
                        )
                    } label: {
                        ProjectEntryRow(entry: entry)
                    }
                } else {
                    // Project entry - navigate to payment list or show add sheet
                    if entry.count == 0 {
                        // No payment methods yet, show add sheet on tap
                        ProjectEntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                                showingAddSheet = true
                            }
                    } else {
                        // Navigate to payment method list
                        NavigationLink {
                            PaymentMethodListView(
                                projectId: entry.projectId,
                                analyticsDelegate: analyticsDelegate
                            )
                        } label: {
                            ProjectEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            if let entry = selectedEntry {
                PaymentMethodAddSheet(
                    projectId: entry.projectId,
                    analyticsDelegate: analyticsDelegate
                ) { _ in
                    dismiss()
                    loadEntries()
                }
                .presentationDetents([.medium])
            }
        }
        .task {
            loadEntries()
            analyticsDelegate?.track(.viewPaymentMethodList)
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
        ProjectSelectionList()
    }
}

#Preview("Single Brand") {
    NavigationStack {
        ProjectSelectionList(brandId: Identifier<Brand>(rawValue: "test-brand"))
    }
}
