//
//  UserAccountDeletedScreen.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.04.25.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

public struct UserAccountDeletedScreen: View {
    @State var urlResource: URL?
    @State var opacityValue: Double = 0

    let onAction: () -> Void
    
    public init(onAction: @escaping () -> Void) {
        self.onAction = onAction
    }

    @ViewBuilder
    var attributedText: some View {
        let description = Asset.localizedString(forKey: "Account.Deleted.Dialog.message")
        if let attributedString = try? AttributedString(markdown: description) {
            Text(attributedString)
        } else {
            Text(description)
        }
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                Text(Asset.localizedString(forKey: "Account.Deleted.Dialog.title"))
                    .fontWeight(.bold)
                
                attributedText
                    .handle(with: $urlResource)
                    .sheet(item: $urlResource) { url in
                        WebView(url: url)
                    }
                
                PrimaryButtonView(title: Asset.localizedString(forKey: "Account.Deleted.Dialog.button")) {
                    onAction()
                }
            }
            .padding()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.shadow(), radius: 6, x: 0, y: 6)
            .padding()
        }
        .opacity(opacityValue)
        .onAppear {
            withAnimation {
                opacityValue = 1.0
            }
        }
        .clearBackground()
    }
}
