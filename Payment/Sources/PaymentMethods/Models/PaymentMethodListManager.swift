//
//  PaymentMethodListManager.swift
//
//
//  Created by Uwe Tilemann on 12.03.26.
//

import Foundation
import SnabbleCore

@Observable
@MainActor
public final class PaymentMethodListManager {
    // Public properties
    public private(set) var paymentGroups: [PaymentGroup] = []
    public private(set) var projectId: Identifier<Project>?
    public private(set) var brandId: Identifier<Brand>?
    public private(set) var isEmpty: Bool = true

    // Project-related computed properties
    public var project: Project? {
        guard let projectId else { return nil }
        return Snabble.shared.project(for: projectId)
    }

    public var availableMethods: [RawPaymentMethod] {
        guard let project else { return [] }
        return project.paymentMethods
            .filter { $0.visible }
            .sorted { $0.displayName < $1.displayName }
    }

    // Initialization
    public init(projectId: Identifier<Project>? = nil, brandId: Identifier<Brand>? = nil) {
        self.projectId = projectId
        self.brandId = brandId
    }

    // MARK: - Data Loading

    public func loadPayments() {
        guard let projectId else {
            paymentGroups = []
            isEmpty = true
            return
        }

        paymentGroups = Snabble.shared.project(for: projectId)?.availablePayments() ?? []
        isEmpty = paymentGroups.isEmpty
    }

    // MARK: - Payment Management

    public func removePayment(_ detail: PaymentMethodDetail) {
        PaymentMethodDetails.remove(detail)
        loadPayments()
    }

    public func removePayment(at indexPath: IndexPath) {
        guard indexPath.section < paymentGroups.count else { return }
        guard indexPath.row < paymentGroups[indexPath.section].items.count else { return }

        let payment = paymentGroups[indexPath.section].items[indexPath.row]

        if let detail = payment.detail {
            PaymentMethodDetails.remove(detail)
            paymentGroups[indexPath.section].remove(at: indexPath.row)
        }
    }

    // MARK: - Method Counting

    public func methodCount(for projectId: Identifier<Project>) -> Int {
        let details = PaymentMethodDetails.read()
        let count = details.filter { detail in
            switch detail.methodData {
            case .teleCashCreditCard(let telecashData):
                return telecashData.projectId == projectId
            case .datatransAlias(let datatransData):
                return datatransData.projectId == projectId
            case .datatransCardAlias(let datatransCardData):
                return datatransCardData.projectId == projectId
            case .payoneCreditCard(let payoneData):
                return payoneData.projectId == projectId
            case .payoneSepa(let payoneSepaData):
                return payoneSepaData.projectId == projectId
            case .sepa, .giropayAuthorization, .invoiceByLogin:
                return Snabble.shared.project(for: projectId)?.paymentMethods.contains(detail.rawMethod) ?? false
            }
        }.count

        return ApplePay.canMakePayments(with: projectId) ? count + 1 : count
    }
}

// MARK: - Project/Brand Entry Management

extension PaymentMethodListManager {
    public struct ProjectEntry: Swift.Identifiable, Hashable {
        public let id: String
        public let projectId: Identifier<Project>
        public let brandId: Identifier<Brand>?
        public let name: String
        public let count: Int

        public var isEmpty: Bool {
            // swiftlint:disable:next:empty_count
            count == 0
        }

        public init(project: Project, count: Int) {
            self.id = project.id.rawValue
            self.projectId = project.id
            self.brandId = project.brandId
            self.name = project.name
            self.count = count
        }

        public init(projectId: Identifier<Project>, brandId: Identifier<Brand>?, name: String, count: Int) {
            self.id = projectId.rawValue
            self.projectId = projectId
            self.brandId = brandId
            self.name = name
            self.count = count
        }
    }

    public func projectEntries(for brandId: Identifier<Brand>) -> [ProjectEntry] {
        return Snabble.shared.projects
            .filter { $0.brandId == brandId }
            .filter { $0.paymentMethods.firstIndex { $0.dataRequired } != nil }
            .sorted { $0.name < $1.name }
            .map { ProjectEntry(project: $0, count: methodCount(for: $0.id)) }
    }

    public func allProjectEntries() -> [ProjectEntry] {
        var allEntries = Snabble.shared.projects
            .filter { !$0.shops.isEmpty }
            .filter { $0.paymentMethods.firstIndex { $0.dataRequired } != nil }
            .map { ProjectEntry(project: $0, count: methodCount(for: $0.id)) }

        // Merge entries belonging to the same brand
        let entriesByBrand = Dictionary(grouping: allEntries, by: { $0.brandId })

        for (brandId, entries) in entriesByBrand {
            guard let brandId = brandId, !entries.isEmpty, let first = entries.first else {
                continue
            }

            let brandProjects = Snabble.shared.projects.filter { $0.brandId == brandId }
            let replacement: ProjectEntry

            if brandProjects.count == 1 {
                // Only one project in brand, use the project's entry without brand
                replacement = ProjectEntry(
                    projectId: first.projectId,
                    brandId: nil,
                    name: first.name,
                    count: first.count
                )
            } else {
                // Overwrite the project's name with the brand name
                if let brand = Snabble.shared.brands.first(where: { $0.id == brandId }) {
                    replacement = ProjectEntry(
                        projectId: first.projectId,
                        brandId: brandId,
                        name: brand.name,
                        count: entries.reduce(0) { $0 + methodCount(for: $1.projectId) }
                    )
                } else {
                    replacement = first
                }
            }

            // Replace all matching entries with the merged one
            allEntries.removeAll(where: { $0.brandId == brandId })
            allEntries.append(replacement)
        }

        return allEntries.sorted { $0.name < $1.name }
    }
}
