//
//  UserConsentScreen.swift
//
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation
import SwiftUI

import SnabbleNetwork
import SnabbleAssetProviding
//import SnabbleUI

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return InnerView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
    
    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }
}

struct ClearBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ClearBackgroundView())
    }
}

extension View {
    func clearBackground() -> some View {
        modifier(ClearBackgroundModifier())
    }
}

struct URLModifier: ViewModifier {
    @Binding var url: URL?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { anUrl in
                if let openUrl = Asset.url(forResource: anUrl.absoluteString, withExtension: nil) {
                    url = openUrl
                    return .handled
                }
                return .systemAction
            })
    }
}

extension View {
    func handle(with url: Binding<URL?>) -> some View {
        modifier(URLModifier(url: url))
    }
}

public struct UserConsentScreen: View {
    let networkManager: NetworkManager
    
    let userConsent: User.Consent
    
    @State var urlResource: URL?
    @State var opacityValue: Double = 0
    
    let onCompletion: (_ userConsent: User.Consent) -> Void
    
    public init(networkManager: NetworkManager, userConsent: User.Consent, onCompletion: @escaping (_ userConsent: User.Consent) -> Void) {
        self.networkManager = networkManager
        self.userConsent = userConsent
        self.onCompletion = onCompletion
    }
    
    @ViewBuilder
    var attributedText: some View {
        let description = Asset.localizedString(forKey: "Consent.description")
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
                Text(Asset.localizedString(forKey: "Consent.title"))
                    .fontWeight(.bold)
                
                attributedText
                    .onOpenURL(perform: { url in
                        print(url)
                    })
//                    .handle(with: $urlResource)
//                    .sheet(item: $urlResource) { url in
//                        Color(.red) // WARNING: Show URL!
////                        print("show \(url.relativePath)")
////                        WebView(url: url)
//                    }
                PrimaryButtonView(title: Asset.localizedString(forKey: "Consent.accept")) {
                    update()
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

    private func update() {
        Task {
            let endpoint = Endpoints.User.update(consent: userConsent)
            try? await networkManager.publisher(for: endpoint)
            onCompletion(userConsent)
        }
    }
}

public protocol UserConsentViewControllerDelegate: AnyObject {
    func userConsentViewControllerDidDismiss(_ viewController: UserConsentViewController)
}

public final class UserConsentViewController: UIHostingController<UserConsentScreen> {
    weak var delegate: UserConsentViewControllerDelegate?
    
    init(networkManager: NetworkManager, userConsent: User.Consent) {
        let rootView = UserConsentScreen(networkManager: networkManager, userConsent: userConsent, onCompletion: { print($0) })
        super.init(rootView: rootView)
        self.modalPresentationStyle = .overFullScreen
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        delegate?.userConsentViewControllerDidDismiss(self)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
