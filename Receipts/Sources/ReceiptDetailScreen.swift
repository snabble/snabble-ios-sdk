//
//  ReceiptDetailScreen.swift
//  Snabble
//
//  Copyright © 2026 snabble. All rights reserved.
//

import SwiftUI
import QuickLook
import SnabbleCore
import MessageUI

/// SwiftUI wrapper for displaying PDF receipts using QLPreviewController
public struct ReceiptDetailScreen: View {
    let orderId: String
    let projectId: Identifier<Project>

    @State private var receiptURL: URL?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showShareSheet = false
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    @State private var order: Order?

    public init(orderId: String, projectId: Identifier<Project>) {
        self.orderId = orderId
        self.projectId = projectId
    }

    public init(provider: any PurchaseProviding) {
        self.orderId = provider.id
        self.projectId = provider.projectId
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            } else if let receiptURL = receiptURL {
                ReceiptPreviewView(url: receiptURL)
            }
        }
        .toolbar {
            if receiptURL != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else {
                                showMailUnavailableAlert = true
                            }
                        } label: {
                            Label("Report Problem", systemImage: "envelope")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = receiptURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showMailComposer) {
            if let url = receiptURL {
                MailComposerView(
                    receiptURL: url,
                    order: order
                )
            }
        }
        .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please configure a mail account in Settings to send problem reports.")
        }
        .task {
            await loadReceipt()
        }
    }

    private func loadReceipt() async {
        guard let project = Snabble.shared.project(for: projectId) ?? Snabble.shared.projects.first else {
            self.error = ReceiptError.missingProject
            self.isLoading = false
            return
        }

        do {
            let order = try await loadOrder(orderId: orderId, project: project)
            let url = try await getReceiptURL(order: order, project: project)
            self.order = order
            self.receiptURL = url
        } catch {
            self.error = error
        }
        self.isLoading = false
    }

    private func loadOrder(orderId: String, project: Project) async throws -> Order {
        return try await withCheckedThrowingContinuation { continuation in
            OrderList.load(project) { result in
                do {
                    let orders = try result.get().receipts
                    guard let order = orders.first(where: { $0.id == orderId && $0.projectId == project.id }) else {
                        continuation.resume(throwing: ReceiptError.missingOrder)
                        return
                    }
                    continuation.resume(returning: order)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func getReceiptURL(order: Order, project: Project) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            order.getReceipt(project) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private enum ReceiptError: LocalizedError {
    case missingProject
    case missingOrder

    var errorDescription: String? {
        switch self {
        case .missingProject:
            return "Project not found"
        case .missingOrder:
            return "Receipt not found"
        }
    }
}

/// UIViewControllerRepresentable wrapper for QLPreviewController
private struct ReceiptPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}
/// UIViewControllerRepresentable wrapper for UIActivityViewController
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// UIViewControllerRepresentable wrapper for MFMailComposeViewController
private struct MailComposerView: UIViewControllerRepresentable {
    let receiptURL: URL
    let order: Order?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        
        composer.setSubject("Receipt Problem Report")
        
        var body = "I would like to report a problem with this receipt.\n\n"
        if let order = order {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            body += "Order ID: \(order.id)\n"
            body += "Date: \(formatter.string(from: order.date))\n\n"
        }
        body += "Please describe the problem:\n\n"
        
        composer.setMessageBody(body, isHTML: false)
        
        if let data = try? Data(contentsOf: receiptURL) {
            composer.addAttachmentData(
                data,
                mimeType: "application/pdf",
                fileName: "receipt.pdf"
            )
        }
        
        let navigationController = UINavigationController(rootViewController: composer)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: { dismiss() })
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onDismiss()
        }
    }
}

