//
//  OnboardingItemView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI

struct URLModifier: ViewModifier {
    @Binding var url: URL

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
    func handle(with url: Binding<URL>) -> some View {
        modifier(URLModifier(url: url))
    }
}

struct OnboardingItemView: View {
    var item: OnboardingItem

    @State var isPresenting: Bool = false
    @State var showURL: Bool = false
    @State var urlResource: URL = URL(fileURLWithPath: "/")

    @State private var attributedText: NSAttributedString?

    @Environment(\.openURL) var openURL

    var topPadding: CGFloat {
        return 40 - (item.title != nil ? 30 : 0)
    }

    @ViewBuilder
    var title: some View {
        VStack {
            if let title = item.title {
                Text(title).font(.title)
            } else {
                EmptyView()
            }
            if let imageSource = item.imageSource {
                if let image = item.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .padding([.top], topPadding)
                } else {
                    Text(imageSource)
                        .font(.system(size: 72))
                        .padding([.top], topPadding)
                }
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    var footer: some View {
        if let resource = item.link {
            Button(action: {
                isPresenting.toggle()
            }) {
                Text(key: "Snabble.Onboarding.Terms.show")
                    .font(.headline)
                    .foregroundColor(Color.accent())
            }
            .sheet(isPresented: $isPresenting) {
                if let url = Asset.url(forResource: resource, withExtension: nil) {
                    ShowWebView(url: url)
                        .padding()
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
            }
        } else {
            AttributedText(htmlString: Asset.localizedString(forKey: item.text ?? ""), openURL: $urlResource)
        }
    }

    @ViewBuilder
    var text: some View {
        attributedTextView
            .multilineTextAlignment(.center)
            .handle(with: $urlResource)
            .onChange(of: urlResource) { _ in
                showURL.toggle()
            }
            .sheet(isPresented: $showURL) {
                if let url = urlResource {
                    ShowWebView(url: url)
                        .padding()
                }
            }
    }

    private func generateAttributedText() {
        guard attributedText == nil, let text = item.text, text.containsHTML == true else { return }

        // create attributedText on main thread since HTML formatter will crash SwiftUI
        DispatchQueue.main.async {
            self.attributedText = Asset.localizedString(forKey: text).attributedStringFromHTML
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            title
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
        let item1 = OnboardingItem(imageSource: "onboarding-image-1", text: "Scan your purchase yourself and pay directly in the app. ", prevButtonTitle: nil, nextButtonTitle: "Continue")
        OnboardingItemView(item: item1)
    }
}
