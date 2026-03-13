//
//  PaymentMethodListView.swift
//
//
//  Created by Claude Code on 12.03.26.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

public struct PaymentMethodListView: View {
    @State private var manager: PaymentMethodListManager
    @State private var showingAddSheet = false

    private weak var analyticsDelegate: AnalyticsDelegate?

    public init(projectId: Identifier<Project>, analyticsDelegate: AnalyticsDelegate? = nil) {
        _manager = State(wrappedValue: PaymentMethodListManager(projectId: projectId))
        self.analyticsDelegate = analyticsDelegate
    }

    public var body: some View {
        Group {
            if manager.isEmpty {
                emptyView
            } else {
                paymentList
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
            }
        }
        .task {
            manager.loadPayments()
            analyticsDelegate?.track(.viewPaymentMethodList)
        }
        .onAppear {
            if manager.isEmpty, let projectId = manager.projectId {
                // Auto-show add sheet if no payments exist
                showingAddSheet = true
            }
        }
    }

    @ViewBuilder
    private var paymentList: some View {
        List {
            ForEach(manager.paymentGroups) { group in
                Section {
                    ForEach(group.items) { payment in
                        PaymentMethodRow(payment: payment)
                            .onTapGesture {
                                handlePaymentTap(payment)
                            }
                    }
                    .onDelete { indexSet in
                        handleDelete(in: group, at: indexSet)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            if let icon = Asset.image(named: "SnabbleSDK/payment/paymentCard") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(.secondary)
            }

            Text(Asset.localizedString(forKey: "Snabble.PaymentMethods.empty"))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func handlePaymentTap(_ payment: Payment) {
        // For now, this is a placeholder. In the full implementation,
        // we would navigate to edit views here based on the payment method type.
        // This requires either wrapping the legacy edit ViewControllers or creating SwiftUI equivalents.
    }

    private func handleDelete(in group: PaymentGroup, at indexSet: IndexSet) {
        for index in indexSet {
            guard index < group.items.count else { continue }
            let payment = group.items[index]

            if let detail = payment.detail {
                manager.removePayment(detail)
            }
        }
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            if let icon = payment.detail?.icon ?? payment.method.icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let detail = payment.detail {
                    Text(detail.displayName)
                        .font(.body)
                } else {
                    Text(payment.method.displayName)
                        .font(.body)
                }

                if let detail = payment.detail {
                    Text(detail.rawMethod.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if payment.detail != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Payment Sheet

struct PaymentMethodAddSheet: View {
    let projectId: Identifier<Project>
    weak var analyticsDelegate: AnalyticsDelegate?

    @State private var manager: PaymentMethodListManager
    @Environment(\.dismiss) private var dismiss

    init(projectId: Identifier<Project>, analyticsDelegate: AnalyticsDelegate?) {
        self.projectId = projectId
        self.analyticsDelegate = analyticsDelegate
        _manager = State(wrappedValue: PaymentMethodListManager(projectId: projectId))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.availableMethods, id: \.rawValue) { method in
                    Button {
                        handleMethodSelection(method)
                    } label: {
                        HStack(spacing: 12) {
                            if let icon = method.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                            }

                            Text(method.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(Asset.localizedString(forKey: "Snabble.PaymentMethods.choose"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Asset.localizedString(forKey: "Snabble.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handleMethodSelection(_ method: RawPaymentMethod) {
        // For now, this is a placeholder.
        // In a full implementation, we would need to handle navigation to the appropriate
        // edit view controller or SwiftUI view based on the payment method type.
        // This is complex because each payment method has different requirements.
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PaymentMethodListView(projectId: Identifier<Project>(rawValue: "test"))
    }
}
