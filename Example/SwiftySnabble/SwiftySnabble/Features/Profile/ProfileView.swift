//
//  ProfileView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI
import SnabbleComponents

struct ProfileView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    
    @State private var showEnvironmentSelector = false

    var body: some View {
        List {
            Section {
                ProfileHeaderView()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Shopping") {
                NavigationLink {
                    ReceiptsView()
                } label: {
                    ProfileRow(
                        icon: "receipt.fill",
                        title: "Receipts",
                        color: .orange
                    )
                }

                NavigationLink {
                    PaymentMethodsViewWrapper(project: appState.project)
                } label: {
                    ProfileRow(
                        icon: "creditcard.fill",
                        title: "Payment Methods",
                        color: .blue
                    )
                }

                NavigationLink {
                    PlaceholderView(title: "Customer Card")
                } label: {
                    ProfileRow(
                        icon: "wallet.pass.fill",
                        title: "Customer Card",
                        color: .purple
                    )
                }
            }

            Section("Settings") {
                NavigationLink {
                    HTMLContentView(title: "Privacy Policy".localized, htmlFileName: "terms")
                } label: {
                    ProfileRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        color: .green
                    )
                }

                NavigationLink {
                    HTMLContentView(title: "Imprint".localized, htmlFileName: "imprint")
                } label: {
                    ProfileRow(
                        icon: "info.circle.fill",
                        title: "Imprint",
                        color: .gray
                    )
                }
            }

            if UserDefaults.standard.developerMode  /*DeveloperMode.isActive*/ {
                Section("Developer") {
                    Button {
//                        DeveloperMode.resetAppId(viewController: nil)
                    } label: {
                        ProfileRow(
                            icon: "trash.fill",
                            title: "Reset App ID",
                            color: .red
                        )
                    }

                    Button {
//                        DeveloperMode.resetClientId(viewController: nil)
                    } label: {
                        ProfileRow(
                            icon: "trash.fill",
                            title: "Reset Client ID",
                            color: .red
                        )
                    }

                    Button {
                        showEnvironmentSelector = true
                    } label: {
                        ProfileRow(
                            icon: "server.rack",
                            title: "Environment: \(DeveloperMode.environmentMode.rawValue)",
                            color: .orange
                        )
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Snabble SDK")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Version \(SDKVersion)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showEnvironmentSelector) {
            EnvironmentSelectorView()
        }
    }
}

struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text("Snabble User")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.gradient)
                )

            Text(title)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environment(AppRouter())
    }
}
