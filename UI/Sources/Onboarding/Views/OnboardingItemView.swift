//
//  OnboardingItemView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI
import SnabbleAssetProviding
import SnabbleComponents

struct URLModifier: ViewModifier {
    @Binding var url: URL?

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
            .environment(\.openURL, OpenURLAction { anUrl in
                if let openUrl = Asset.url(forResource: anUrl.absoluteString, withExtension: nil) {
                    url = openUrl
                    return .handled
                }
                return .systemAction
            })
        } else {
            content
        }
    }
}
extension View {
    func handle(with url: Binding<URL?>) -> some View {
        modifier(URLModifier(url: url))
    }
}

struct OnboardingItemView: View {
    var item: OnboardingItem

    @State var isPresenting: Bool = false
    @State var urlResource: URL?

    @State private var attributedText: NSAttributedString?

    @Environment(\.openURL) var openURL

    @ViewBuilder
    var image: some View {
        if let image = item.image {
            image
                .resizable()
                .scaledToFit()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var footer: some View {
        if let resource = item.link {
            Button(action: {
                isPresenting.toggle()
            }) {
                Text(keyed: "Snabble.Onboarding.Link.show")
                    .font(.headline)
                    .foregroundColor(Color.projectPrimary())
            }
            .sheet(isPresented: $isPresenting) {
                if let url = Asset.url(forResource: resource, withExtension: nil) {
                    WebView(url: url)
                }
            }

        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var attributedTextView: some View {
        if #available(iOS 15.0, *) {
            if let attrString = attributedText {
                Text(AttributedString(attrString))
            } else {
                Text(item.attributedString)
                    .tint(.projectPrimary())
            }
        } else {
            AttributedText(htmlString: Asset.localizedString(forKey: item.text), openURL: $urlResource)
        }
    }

    @ViewBuilder
    var text: some View {
        attributedTextView
            .multilineTextAlignment(.center)
            .handle(with: $urlResource)
            .sheet(item: $urlResource) { url in
                WebView(url: url)
            }
    }

    private func generateAttributedText() {
        guard attributedText == nil, item.text.containsHTML == true else { return }

        // create attributedText on main thread since HTML formatter will crash SwiftUI
        DispatchQueue.main.async {
            self.attributedText = Asset.localizedString(forKey: item.text).attributedStringFromHTML
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            image
            text
            footer
        }
        .padding([.leading, .trailing], 50)
        .onAppear {
            generateAttributedText()
        }
    }
}

struct OnboardingItemView_Previews: PreviewProvider {
    static var previews: some View {
        let item1 = OnboardingItem(
            text: "Scan your purchase yourself and pay directly in the app."
        )
        OnboardingItemView(item: item1)
    }
}
