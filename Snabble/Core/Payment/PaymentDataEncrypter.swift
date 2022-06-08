//
//  PaymentDataEncrypter.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import Security

// just a marker protocol
protocol PaymentRequestOrigin: Encodable { }

struct PaymentDataEncrypter {
    /// the root certificate in DER format
    private var rootCertificate: Data?
    /// the encryption certificate in DER format
    private var certificate: Data?

    init?(_ gatewayCert: Data?) {
        let caName = "\(Snabble.config.environment.name)-ca"
        guard
            let gatewayCert = gatewayCert,
            let rootPath = SnabbleSDKBundle.main.path(forResource: caName, ofType: "der")
        else {
            return nil
        }

        do {
            self.rootCertificate = try Data(contentsOf: URL(fileURLWithPath: rootPath))
            self.certificate = gatewayCert
        } catch {
            Log.error("can't read root certificate: \(error)")
            return nil
        }
    }

    func encrypt<T: PaymentRequestOrigin>(_ obj: T) -> (String, String)? {
        guard
            let data = try? JSONEncoder().encode(obj),
            let plainText = String(bytes: data, encoding: .utf8),
            let cipherText = self.encrypt(plainText),
            let serial = self.getSerial()
        else {
            return nil
        }

        return (cipherText, serial)
    }

    func getSerial() -> String? {
        guard
            let certificate = self.certificate,
            let cert = SecCertificateCreateWithData(nil, certificate as CFData)
        else {
            return nil
        }

        var error: Unmanaged<CFError>?
        let serial = SecCertificateCopySerialNumberData(cert, &error)
        if let serial = serial as Data? {
            let hex = serial.map { String(format: "%02hhx", $0) }.joined()
            return hex
        }

        return nil
    }

    private func encrypt(_ plainText: String) -> String? {
        guard
            let rootCertificate = self.rootCertificate,
            let certificate = self.certificate,
            let root = SecCertificateCreateWithData(nil, rootCertificate as CFData),
            let cert = SecCertificateCreateWithData(nil, certificate as CFData)
        else {
            return nil
        }

        let certs: NSArray = [cert, root]
        var secTrustResult: SecTrust?
        let status = SecTrustCreateWithCertificates(certs, nil, &secTrustResult)
        guard status == errSecSuccess else {
            return nil
        }

        guard let secTrust = secTrustResult else {
            return nil
        }

        // set our root CA as the anchor
        let anchors: NSArray = [ root ]
        SecTrustSetAnchorCertificates(secTrust, anchors)

        // check if cerficate and root match
        guard SecTrustEvaluateWithError(secTrust, nil) else {
            return nil
        }

        // encrypt the payment data
        let publicKeyRef: SecKey?
        if #available(iOS 14, *) {
            publicKeyRef = SecTrustCopyKey(secTrust)
        } else {
            publicKeyRef = SecTrustCopyPublicKey(secTrust)
        }


        if let publicKeyRef = publicKeyRef, let plainTextData = plainText.data(using: .utf8) {
            var error: Unmanaged<CFError>?
            if let cipher = SecKeyCreateEncryptedData(publicKeyRef, .rsaEncryptionOAEPSHA256, plainTextData as CFData, &error) as Data? {
                return cipher.base64EncodedString()
            }
        }

        return nil
    }

}
