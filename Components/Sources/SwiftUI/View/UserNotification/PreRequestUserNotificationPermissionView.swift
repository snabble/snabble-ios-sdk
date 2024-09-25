
//
//  PreRequestUserNotificationView.swift
//  SnabbleComponents
//
//  Created by Andreas Osberghaus on 25.09.24.
//

import SwiftUI
import UserNotifications
import SnabbleAssetProviding

struct PreRequestUserNotificationPermissionView: View {
    let notificationCenter: UNUserNotificationCenter
    let options: UNAuthorizationOptions
    let completion: (_ isAuthorized: Bool?) -> Void
    
    var body: some View {
        VStack {
            Text(Asset.localizedString(forKey: "Snabble.Notifications.Dialog.title"))
            Text(Asset.localizedString(forKey: "Snabble.Notifications.Dialog.message"))
            Button {
                requestAuthorization()
            } label: {
                Text(Asset.localizedString(forKey: "Snabble.Notifications.Dialog.requestPermission"))
            }
            Button {
                completion(nil)
            } label: {
                Text(Asset.localizedString(forKey: "Snabble.Notifications.Dialog.reject"))
            }
        }
    }
    
    private func requestAuthorization() {
        Task {
            var isAuthorized: Bool? = nil
            let settings = await notificationCenter.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                isAuthorized = try await notificationCenter.requestAuthorization(options: options)
            case .denied:
                isAuthorized = false
            case .authorized, .provisional, .ephemeral:
                isAuthorized = true
            @unknown default:
                break
            }
            completion(isAuthorized)
        }
    }
}

struct UserNotificationDialogViewModifier: ViewModifier {
    @Binding var isAllowedToBePresented: Bool
    
    let notificationCenter: UNUserNotificationCenter
    let options: UNAuthorizationOptions
    let completion: (_ isAuthorized: Bool?) -> Void
    
    @State private var shouldBePresented: Bool = false

    private var isShowing: Bool {
        shouldBePresented && isAllowedToBePresented
    }
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isShowing ? 1 : 0)
            .overlay(
                contentView
                    .animation(.spring(), value: isShowing)
            )
            .task() {
                let settings = await notificationCenter.notificationSettings()
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    shouldBePresented = true
                case .denied, .notDetermined:
                    shouldBePresented = false
                @unknown default:
                    shouldBePresented = false
                }
            }
        
    }
    
    @ViewBuilder var contentView: some View {
        if isShowing {
            ZStack(alignment: .center) {
                Color.black
                    .opacity(0.3)
                GeometryReader { geometry in
                    PreRequestUserNotificationPermissionView(
                        notificationCenter: notificationCenter,
                        options: options,
                        completion: completion
                    )
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
            }
            .ignoresSafeArea()
        }
    }
}

extension View {
    public func userNotificationDialog(
        isAllowedToBePresented: Binding<Bool>,
        notificationCenter: UNUserNotificationCenter = .current(),
        options: UNAuthorizationOptions = [.alert, .badge, .sound],
        completion: @escaping (_ isAuthorized: Bool?) -> Void) -> some View {
        modifier(UserNotificationDialogViewModifier(
            isAllowedToBePresented: isAllowedToBePresented,
            notificationCenter: notificationCenter,
            options: options,
            completion: completion)
        )
    }
}
