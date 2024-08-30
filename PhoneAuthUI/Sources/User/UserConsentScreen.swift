////
////  UserConsentScreen.swift
////  teo
////
////  Created by Uwe Tilemann on 04.03.24.
////
//
//import SwiftUI
//
//import SnabbleCore
//import SnabbleNetwork
//import SnabbleAssetProviding
//import SnabbleUI
//
//struct ClearBackgroundView: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//        return InnerView()
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) { }
//    
//    private class InnerView: UIView {
//        override func didMoveToWindow() {
//            super.didMoveToWindow()
//            superview?.superview?.backgroundColor = .clear
//        }
//    }
//}
//
//struct ClearBackgroundModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .background(ClearBackgroundView())
//    }
//}
//
//extension View {
//    func clearBackground() -> some View {
//        modifier(ClearBackgroundModifier())
//    }
//}
//
//struct URLModifier: ViewModifier {
//    @Binding var url: URL?
//
//    func body(content: Content) -> some View {
//        content
//            .environment(\.openURL, OpenURLAction { anUrl in
//                if let openUrl = Asset.url(forResource: anUrl.absoluteString, withExtension: nil) {
//                    url = openUrl
//                    return .handled
//                }
//                return .systemAction
//            })
//    }
//}
//
//extension View {
//    func handle(with url: Binding<URL?>) -> some View {
//        modifier(URLModifier(url: url))
//    }
//}
//
//public struct UserConsentScreen: View {
//    let networkManager: NetworkManager
//    let user: SnabbleNetwork.User
//    
//    @State var urlResource: URL?
//    @State var opacityValue: Double = 0
//    
//    public init(networkManager: NetworkManager, user: SnabbleNetwork.User) {
//        self.networkManager = networkManager
//        self.user = user
//    }
//    
//    @ViewBuilder
//    var attributedText: some View {
//        let description = Asset.localizedString(forKey: "Consent.description")
//        if let attributedString = try? AttributedString(markdown: description) {
//            Text(attributedString)
//        } else {
//            Text(description)
//        }
//    }
//    
//    public var body: some View {
//        ZStack {
//            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
//            VStack(spacing: 24) {
//                Text(Asset.localizedString(forKey: "Consent.title"))
//                    .fontWeight(.bold)
//                
//                attributedText
//                    .handle(with: $urlResource)
//                    .sheet(item: $urlResource) { url in
//                        WebView(url: url)
//                    }
//                PrimaryButtonView(title: Asset.localizedString(forKey:"Consent.accept")) {
//                    update()
//                }
//            }
//            .padding()
//            .multilineTextAlignment(.center)
//            .frame(maxWidth: .infinity)
//            .background(Color.systemBackground)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            .shadow(color: Color.shadow(), radius: 6, x: 0, y: 6)
//            .padding()
//        }
//        .opacity(opacityValue)
//        .onAppear {
//            withAnimation {
//                opacityValue = 1.0
//            }
//        }
//        .clearBackground()
//    }
//
//    private func update() {
//        Task {
//            let consent = SnabbleNetwork.User.Consent(version: "1.0")
//            let endpoint = Endpoints.User.update(consent: consent)
//
//            try? await networkManager.publisher(for: endpoint)
//            user.update(withConsent: consent)
//        }
//    }
//}
//
//public protocol UserConsentViewControllerDelegate: AnyObject {
//    func userConsentViewControllerDidDismiss(_ viewController: UserConsentViewController)
//}
//
//public final class UserConsentViewController: UIHostingController<UserConsentScreen> {
//    weak var delegate: UserConsentViewControllerDelegate?
//    
//    init(networkManager: NetworkManager, user: SnabbleNetwork.User) {
//        super.init(rootView: UserConsentScreen(networkManager: networkManager, user: user))
//        self.modalPresentationStyle = .overFullScreen
//    }
//    public override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        
//        delegate?.userConsentViewControllerDidDismiss(self)
//    }
//    
//    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
