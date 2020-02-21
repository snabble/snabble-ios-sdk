//
//  BiometricAuthentication.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication

// helpful blog post: http://michael-brown.net/2018/touch-id-and-face-id-on-ios/

public enum BiometricAuthentication {

    public enum BiometryType {
        case none
        case touchID
        case faceID

        public var name: String {
            switch self {
            case .none: return ""
            case .touchID: return "Snabble.Biometry.TouchId".localized()
            case .faceID: return "Snabble.Biometry.FaceId".localized()
            }
        }
    }

    public enum AuthenticationResult {
        case proceed
        case cancelled
        case locked
    }

    private static let policy = LAPolicy.deviceOwnerAuthentication

    public static var supportedBiometry: BiometryType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            _ = authContext.canEvaluatePolicy(self.policy, error: nil)
            switch authContext.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            @unknown default:
                return .none
            }
        } else {
            return authContext.canEvaluatePolicy(self.policy, error: nil) ? .touchID : .none
        }
    }

    static func requestAuthentication(for reason: String, _ reply: @escaping (Bool, Error?) -> Void ) {
        var localAuth = self.useBiometry

        if localAuth {
            let authContext = LAContext()
            if #available(iOS 11, *) {
                _ = authContext.canEvaluatePolicy(self.policy, error: nil)
                switch authContext.biometryType {
                case .none: localAuth = false
                case .touchID: break
                case .faceID: break
                @unknown default: localAuth = false
                }
            } else {
                localAuth = authContext.canEvaluatePolicy(policy, error: nil)
            }

            if localAuth {
                authContext.localizedFallbackTitle = "Snabble.Biometry.enterCode".localized()
                authContext.evaluatePolicy(policy, localizedReason: reason) { success, error in
                    if let error = error {
                        NSLog("local authentication error: \(error)")
                    }
                    DispatchQueue.main.async {
                        reply(success, error)
                    }
                }
            }
        } else {
            reply(true, nil)
        }
    }
}

// MARK: - user preferences
extension BiometricAuthentication {

    public enum SettingsKeys {
        public static let useBiometryTouchId = "useBiometryTOUCHID"
        public static let useBiometryFaceId = "useBiometryFACEID"
    }

    public static var useBiometry: Bool {
        get {
            let settings = UserDefaults.standard
            switch BiometricAuthentication.supportedBiometry {
            case .faceID: return settings.bool(forKey: SettingsKeys.useBiometryFaceId)
            case .touchID: return settings.bool(forKey: SettingsKeys.useBiometryTouchId)
            case .none: return false
            }
        }
        set {
            let settings = UserDefaults.standard
            switch BiometricAuthentication.supportedBiometry {
            case .faceID: settings.set(newValue, forKey: SettingsKeys.useBiometryFaceId)
            case .touchID: settings.set(newValue, forKey: SettingsKeys.useBiometryTouchId)
            case .none: ()
            }
        }
    }

}

extension BiometricAuthentication {

    public static func requestAuthentication(for reason: String, _ presenter: UIViewController, _ completion: @escaping (AuthenticationResult) -> Void ) {
        guard BiometricAuthentication.useBiometry else {
            completion(.proceed)
            return
        }

        BiometricAuthentication.requestAuthentication(for: reason) { success, error in
            if let error = error as? LAError {
                let cancelCodes = [ LAError.Code.userCancel.rawValue, LAError.Code.appCancel.rawValue, LAError.Code.systemCancel.rawValue ]
                if cancelCodes.contains(error.errorCode) {
                    completion(.cancelled)
                    return
                }

                var lockoutCodes = [ LAError.Code.touchIDLockout.rawValue ]
                if #available(iOS 11.0, *) {
                    lockoutCodes.append(LAError.Code.biometryLockout.rawValue)
                }

                if lockoutCodes.contains(error.errorCode) {
                    completion(.locked)
                    return
                }
            }

            if success {
                completion(.proceed)
            } else {
                completion(.cancelled)
            }
        }
    }
}
