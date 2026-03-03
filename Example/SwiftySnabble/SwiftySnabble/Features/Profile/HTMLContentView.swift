//
//  HTMLContentView.swift
//  SwiftySnabble
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//
import SwiftUI

import SnabbleComponents

struct HTMLContentView: View {
    let title: String
    let htmlFileName: String
    @State private var htmlContent: String?
    
    var body: some View {
        Group {
            if let htmlContent {
                SnabbleComponents.HTMLView(string: htmlContent)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading \(title)...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHTML()
        }
    }
    
    private func loadHTML() async {
        guard let url = Bundle.main.url(forResource: htmlFileName, withExtension: "html"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        htmlContent = content
    }
}

