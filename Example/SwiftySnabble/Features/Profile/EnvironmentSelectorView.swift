//
//  EnvironmentSelectorView.swift
//  SwiftySnabble
//
//  Created by Uwe Tilemann on 18.05.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//
import SwiftUI

import SnabbleCore
import SnabbleTheme

struct EnvironmentSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEnvironment = DeveloperMode.environmentMode

    var body: some View {
        NavigationStack {
            List {
                ForEach([Snabble.Environment.production, .staging, .testing], id: \.self) { env in
                    Button {
                        selectedEnvironment = env
                        // Note: Environment switching requires app restart
                        dismiss()
                    } label: {
                        HStack {
                            Text(env.rawValue)
                            Spacer()
                            if env == selectedEnvironment {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Environment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

