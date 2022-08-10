//
//  OnboardingItemView.swift
//  Onboarding
//
//  Created by Uwe Tilemann on 05.08.22.
//

import SwiftUI

struct URLModifier: ViewModifier {
    @Binding var url: URL
    
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
            .environment(\.openURL, OpenURLAction { anUrl in
                if let openUrl = AssetProvider.shared.url(forResource: anUrl.absoluteString, withExtension: nil) {
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
            if item.imageFromSource != nil, let image = item.image {
                image.resizable().scaledToFit().padding([.top], topPadding)

            } else {
                if let src = item.imageSource {
                    Text(src).font(.system(size: 72)).padding([.top], topPadding)
                } else {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    var footer: some View {
        if let resource = item.link {
            Button(action: {
                isPresenting.toggle()
            }) {
                Text("Show").font(.headline)
            }
            .sheet(isPresented: $isPresenting) {
                if let url = Bundle.main.url(forResource: resource, withExtension: nil) {
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
            AttributedText(htmlString: item.text ?? "", openURL: $urlResource)
        }
    }
    
    @ViewBuilder
    var text: some View {
        attributedTextView
            .multilineTextAlignment(.center)
            .handle(with: $urlResource)
//            .environment(\.openURL, OpenURLAction { url in
//                if let url = AssetProvider.shared.url(forResource: url.absoluteString, withExtension: nil) {
//                    urlResource = url
//                    return .handled
//                }
//                return .systemAction
//            })
            .onChange(of: urlResource) { url in
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
            self.attributedText = text.attributedStringFromHTML
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            title
            text
            footer
        }
        .padding([.leading, .trailing], 50)
        .onAppear() {
            generateAttributedText()
        }
    }
}

struct OnboardingItemView_Previews: PreviewProvider {
    
    static var previews: some View {
        let item1 = OnboardingItem(id:1001, imageSource: "onboarding-image-1", text: "Scan your purchase yourself and pay directly in the app. ", prevButtonTitle: nil, nextButtonTitle: "Continue")
        OnboardingItemView(item: item1)
    }
}

