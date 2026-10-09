//
//  SessionsView.swift
//  SnabblePayExample
//

import SwiftUI
import SnabblePay

private extension Session {
    var statusText: String {
        guard let transaction else {
            return "No transaction yet"
        }
        return transaction.state.rawValue.capitalized
    }
}

struct SessionsView: View {
    @State private var viewModel = SessionsViewModel()
    private let errorHandler = ErrorHandler.shared

    @State private var showError = false

    var body: some View {
        List {
            if let sessions = viewModel.sessions {
                if sessions.isEmpty {
                    ContentUnavailableView("No Sessions", systemImage: "clock.arrow.circlepath")
                } else {
                    ForEach(sessions, id: \.id) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.account.name)
                                .font(.headline)
                            Text("Created: \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Expires: \(session.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.delete(session: session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.loadSessions()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
        .onChange(of: errorHandler.error) { _, error in
            if error != nil {
                showError = true
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(errorHandler.error?.localizedAction ?? "Error"),
                  message: Text(errorHandler.error?.localizedReason ?? "An error occured"))
        }
    }
}
