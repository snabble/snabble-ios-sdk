//
//  SnabbleAPI+Pinning.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import TrustKit

/// use Trustkit for certificate pinning

extension SnabbleAPI {

    private static let CAHashes = [
        // let's encrypt
        "YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=", "sRHdihwgkaib1P1gxX8HFszlD+7/gTfNvuAybgLPNis=",
        // backup CAs
        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", "lCppFqbkrlJ3EcVFAkeip0+44VaoJUymbnOaEUk7tEU=",
        "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=", "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=",
        "WoiWRyIOVNa9ihaBciRSC7XHjliYS9VwUGOIud4PB18=", "h6801m+z8v3zbgkRHpq6L29Esgfzhj89C1SyUCOQmqU=",
        "q5hJUnat8eyv8o81xTBIeB5cFxjaucjmelBPT2pRMo8=", "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
        "SQVGZiOrQXi+kqxcvWWE96HhfydlLVqFr4lQTqI5qqo="
    ]

    static func initializeTrustKit() {
        let trustKitConfig: [String: Any] = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "snabble.io": [
                    kTSKExpirationDate: "2021-03-17",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ],
                "snabble-testing.io": [
                    kTSKExpirationDate: "2021-03-17",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ],
                "snabble-staging.io": [
                    kTSKExpirationDate: "2021-03-17",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ]
            ]
        ]

        TrustKit.initSharedInstance(withConfiguration:trustKitConfig)

        TrustKit.sharedInstance().pinningValidatorCallback = { result, hostname, policy in
            if result.finalTrustDecision != .shouldAllowConnection {
                Log.error("untrusted connection to \(hostname) denied: eval=\(result.evaluationResult.rawValue) final=\(result.finalTrustDecision.rawValue)")
            }
        }
    }

    ///
    /// create a URLSession that is suitable for making requests to the snabble servers
    /// and verifies the CAs
    ///
    /// - Returns: a URLSession object
    static public func urlSession() -> URLSession {
        let checker = CertificatePinningDelegate()
        let session = URLSession(configuration: .default, delegate: checker, delegateQueue: nil)
        return session
    }
}

/// handle the certificate pinning checks for our requests
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let handled = TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler)
        if !handled {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
