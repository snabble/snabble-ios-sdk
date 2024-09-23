//
//  UserNotificationToggle.swift
//  Components
//
//  Created by Andreas Osberghaus on 2024-09-23.
//

import SwiftUI
import UserNotifications
import SnabbleAssetProviding

public struct UserNotificationToggle: View {
    @Environment(\.scenePhase) var scenePhase
    
    public let notificationCenter: UNUserNotificationCenter
    
    @State private var taskTrigger: Bool = false
    @State private var isAuthorized: Bool = false
    
    public init(notificationCenter: UNUserNotificationCenter = .current(), didRequestAuthorization: @escaping (Bool) -> Void) {
        self.notificationCenter = notificationCenter
        self.didRequestAuthorization = didRequestAuthorization
    }
    
    public var didRequestAuthorization: ((Bool) -> Void)?
    
    public var body: some View {
        Toggle(Asset.localizedString(forKey: "Snabble.pushMessages"),
               isOn: .init(
                get: { isAuthorized },
                set: { newValue in
                    if newValue {
                        Task {
                            let settings = await notificationCenter.notificationSettings()
                            switch settings.authorizationStatus {
                            case .notDetermined:
                                let isAuthorized = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                                didRequestAuthorization?(isAuthorized)
                            case .denied:
                                await openSettings()
                            case .authorized, .provisional, .ephemeral:
                                break
                            @unknown default:
                                break
                            }
                            taskTrigger.toggle()
                        }
                    } else {
                        Task {
                            await openSettings()
                        }
                    }
                })
        )
        .task(id: taskTrigger) {
            let settings = await notificationCenter.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                isAuthorized = true
            case .denied, .notDetermined:
                isAuthorized = false
            @unknown default:
                isAuthorized = false
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                taskTrigger.toggle()
            case .background, .inactive:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func openSettings() async {
        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
            await UIApplication.shared.open(appSettings)
        }
    }
}
