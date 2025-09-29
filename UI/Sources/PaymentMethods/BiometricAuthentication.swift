//
//  BiometricAuthentication.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication
import SnabbleAssetProviding

// helpful blog post: http://michael-brown.net/2018/touch-id-and-face-id-on-ios/

public enum BiometricAuthentication {
    public enum BiometryType {
        case none
        case touchID
        case faceID

        public var name: String {
            switch self {
            case .none: return ""
            case .touchID: return Asset.localizedString(forKey: "Snabble.Biometry.touchId")
            case .faceID: return Asset.localizedString(forKey: "Snabble.Biometry.faceId")
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
        _ = authContext.canEvaluatePolicy(self.policy, error: nil)
        switch authContext.biometryType {
        case .none, .opticID:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }

    static func requestAuthentication(for reason: String, _ reply: @escaping @Sendable (Bool, Error?) -> Void ) {
        let authContext = LAContext()
        let canEvaluate = authContext.canEvaluatePolicy(self.policy, error: nil)

        if canEvaluate && (authContext.biometryType == .touchID || authContext.biometryType == .faceID) {
            authContext.localizedFallbackTitle = Asset.localizedString(forKey: "Snabble.Biometry.enterCode")
            authContext.evaluatePolicy(policy, localizedReason: reason) { success, error in
                if let error = error {
                    NSLog("local authentication error: \(error)")
                }
                DispatchQueue.main.async {
                    reply(success, error)
                }
            }
        } else {
            DispatchQueue.main.async {
                reply(false, nil)
            }
        }
    }
}

extension BiometricAuthentication {
    static func requestAuthentication(for reason: String, completion: @escaping @Sendable (AuthenticationResult) -> Void ) {
        BiometricAuthentication.requestAuthentication(for: reason) { success, error in
            if let error = error as? LAError {
                let cancelCodes = [ LAError.Code.userCancel, LAError.Code.appCancel, LAError.Code.systemCancel ]
                if cancelCodes.contains(error.code) {
                    completion(.cancelled)
                    return
                }

                if error.code == .biometryLockout {
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
