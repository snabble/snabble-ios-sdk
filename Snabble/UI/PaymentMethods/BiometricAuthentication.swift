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
    }

    static func requestAuthentication(for reason: String, _ reply: @escaping (Bool, Error?) -> Void ) {
        let authContext = LAContext()
        let canEvaluate = authContext.canEvaluatePolicy(self.policy, error: nil)

        if canEvaluate && (authContext.biometryType == .touchID || authContext.biometryType == .faceID) {
            authContext.localizedFallbackTitle = "Snabble.Biometry.enterCode".localized()
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

    public static func requestAuthentication(for reason: String, _ presenter: UIViewController, _ completion: @escaping (AuthenticationResult) -> Void ) {
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
