//
//  SnabbleAPI+Pinning.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import TrustKit

/// use Trustkit for certificate pinning

extension SnabbleAPI {
    private static let CAHashes = [
        // Let's Encrypt X3 cross-signed
        "YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=",
        // Let's Encrypt X4 cross-signed
        "sRHdihwgkaib1P1gxX8HFszlD+7/gTfNvuAybgLPNis=",
        // Let's Encrypt E1
        "J2/oqMTsdhFWW/n85tys6b4yDBtb6idZayIEBx7QTxA=",
        // Let's Encrypt E2
        "vZNucrIS7293MQLGt304+UKXMi78JTlrwyeUIuDIknA=",
        // Let's Encrypt R3 cross-signed
        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=",
        // Let's Encrypt R4 cross-signed
        "5VReIRNHJBiRxVSgOTTN6bdJZkpZ0m1hX+WPd5kPLQM=",

        // backup CAs
        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // ISRG Root X1
        "lCppFqbkrlJ3EcVFAkeip0+44VaoJUymbnOaEUk7tEU=", // AddTrust External Root
        "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=", // DigiCert Global Root
        "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=", // DigiCert Global Root G2
        "WoiWRyIOVNa9ihaBciRSC7XHjliYS9VwUGOIud4PB18=", // DigiCert HA Root
        "h6801m+z8v3zbgkRHpq6L29Esgfzhj89C1SyUCOQmqU=", // GeoTrust Global
        "q5hJUnat8eyv8o81xTBIeB5cFxjaucjmelBPT2pRMo8=", // GeoTrust PCA G3 Root
        "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=", // GeoTrust PCA G4
        "SQVGZiOrQXi+kqxcvWWE96HhfydlLVqFr4lQTqI5qqo="  // GeoTrust PCA
    ]

    static func initializeTrustKit() {
        let trustKitConfig: [String: Any] = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "snabble.io": [
                    kTSKExpirationDate: "2025-09-15",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ],
                "snabble-testing.io": [
                    kTSKExpirationDate: "2025-09-15",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ],
                "snabble-staging.io": [
                    kTSKExpirationDate: "2025-09-15",
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKPublicKeyHashes: SnabbleAPI.CAHashes
                ]
            ]
        ]

        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)

        TrustKit.sharedInstance().pinningValidatorCallback = { result, hostname, _ in
            if result.finalTrustDecision != .shouldAllowConnection {
                Log.error("untrusted connection to \(hostname) denied: eval=\(result.evaluationResult.rawValue) final=\(result.finalTrustDecision.rawValue)")
            }
        }
    }

    ///
    /// get a URLSession that is suitable for making requests to the snabble servers
    /// and verifies the CAs
    ///
    /// - Returns: a URLSession object
    public static func urlSession() -> URLSession {
        return pinningSession
    }

    static let pinningSession: URLSession = {
        let checker = CertificatePinningDelegate()
        let session = URLSession(configuration: .default, delegate: checker, delegateQueue: nil)
        return session
    }()
}

/// handle the certificate pinning checks for our requests
internal class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard SnabbleAPI.config.useCertificatePinning else {
            return completionHandler(.performDefaultHandling, nil)
        }

        let handled = TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler)
        if !handled {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
