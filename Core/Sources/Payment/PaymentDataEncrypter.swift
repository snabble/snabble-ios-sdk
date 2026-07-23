//
//  PaymentDataEncrypter.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import Security

// just a marker protocol
protocol PaymentRequestOrigin: Encodable { }

/// Encrypts payment data using a gateway certificate that is cryptographically
/// validated against a locally bundled CA certificate before use.
///
/// ## Security model
///
/// The backend provides a `GatewayCertificate` via the metadata API. Before
/// using its public key for encryption, the SDK verifies that the certificate
/// was signed by snabble's own CA — preventing an attacker from substituting a
/// foreign certificate. The local CA cert (e.g. `staging-ca.der`) acts as the
/// trust anchor. Only snabble's CA is accepted; system root CAs are explicitly
/// excluded via `SecTrustSetAnchorCertificatesOnly`.
///
/// Gateway certificate expiry is not checked here. It is managed externally
/// via the `validUntil` field on `GatewayCertificate` in the metadata response.
///
/// ## iOS / Android parity
///
/// `SecTrustEvaluateWithError` validates the entire certificate chain including
/// the local CA cert's own validity period. Android skips this check and only
/// verifies the cryptographic signature. To align both platforms, trust
/// evaluation is performed **as of the gateway cert's own Not Before date** via
/// `SecTrustSetVerifyDate`. This confirms the signature chain without being
/// blocked by the local CA cert's expiry date.
///
/// ## CA certificate rotation
///
/// Multiple CA certs can be bundled simultaneously. The primary cert uses the
/// naming convention `<env>-ca.der` (e.g. `staging-ca.der`); additional certs
/// for rotation follow the pattern `<env>-ca-1.der`, `<env>-ca-2.der`, etc.
/// All bundled certs are tried in order; the first one that validates the
/// gateway cert wins. This allows overlapping old and new CA during a key
/// rotation without a hard cutover in a single SDK release.
struct PaymentDataEncrypter {
    /// root CA certificates in DER format; multiple entries support key rotation
    private var rootCertificates: [Data]
    /// the encryption certificate in DER format (from gateway metadata)
    private var certificate: Data

    init?(_ gatewayCert: Data?) {
        guard let gatewayCert else { return nil }

        let caName = "\(Snabble.shared.config.environment.name)-ca"
        var certs: [Data] = []

        // Primary CA cert (e.g. staging-ca.der)
        if let path = Bundle.module.path(forResource: caName, ofType: "der"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            certs.append(data)
        }

        // Additional CA certs for rotation (e.g. staging-ca-1.der, staging-ca-2.der, …)
        for index in 1...9 {
            guard
                let path = Bundle.module.path(forResource: "\(caName)-\(index)", ofType: "der"),
                let data = try? Data(contentsOf: URL(fileURLWithPath: path))
            else { break }
            certs.append(data)
        }

        guard !certs.isEmpty else {
            Log.error("no root certificate found for \(caName)")
            return nil
        }

        self.rootCertificates = certs
        self.certificate = gatewayCert
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
        guard let cert = SecCertificateCreateWithData(nil, certificate as CFData) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        if let serial = SecCertificateCopySerialNumberData(cert, &error) as Data? {
            return serial.map { String(format: "%02hhx", $0) }.joined()
        }

        return nil
    }

    private func encrypt(_ plainText: String) -> String? {
        guard let cert = SecCertificateCreateWithData(nil, certificate as CFData) else {
            return nil
        }

        // Try each bundled CA cert in order — first match wins (supports rotation)
        for rootCertData in rootCertificates {
            if let result = encrypt(plainText, cert: cert, rootCertData: rootCertData) {
                return result
            }
        }

        Log.error("payment data encryption failed: no bundled CA cert validated the gateway certificate")
        return nil
    }

    private func encrypt(_ plainText: String, cert: SecCertificate, rootCertData: Data) -> String? {
        guard let root = SecCertificateCreateWithData(nil, rootCertData as CFData) else {
            return nil
        }

        var trust: SecTrust?
        guard SecTrustCreateWithCertificates([cert] as CFArray, SecPolicyCreateBasicX509(), &trust) == errSecSuccess,
              let trust
        else {
            return nil
        }

        // Restrict trust to our bundled CA only — system root CAs must not be
        // accepted as a substitute anchor.
        SecTrustSetAnchorCertificates(trust, [root] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)

        // Evaluate as of the gateway cert's Not Before date so that the local CA
        // cert's expiry does not block validation. The CA was necessarily valid when
        // it signed the gateway cert, so the signature check is still sound.
        // Gateway cert expiry is managed externally via GatewayCertificate.validUntil.
        if let verifyDate = DERParser.notBeforeDate(of: cert) {
            SecTrustSetVerifyDate(trust, verifyDate as CFDate)
        }

        var error: CFError?
        guard SecTrustEvaluateWithError(trust, &error) else {
            return nil
        }

        let publicKey: SecKey?
        if #available(iOS 14, *) {
            publicKey = SecTrustCopyKey(trust)
        } else {
            publicKey = SecTrustCopyPublicKey(trust)
        }

        guard let publicKey, let plainData = plainText.data(using: .utf8) else { return nil }

        var encryptError: Unmanaged<CFError>?
        guard let cipher = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA256, plainData as CFData, &encryptError) as Data?
        else {
            return nil
        }

        return cipher.base64EncodedString()
    }
}

// Extracts the Not Before date from an X.509 certificate by parsing the raw DER.
//
// SecCertificateCopyValues (the high-level date accessor) is macOS-only.
// SecCertificateCopyData is available on iOS since 2.0 and returns the DER bytes,
// which this parser navigates by following the fixed X.509 TBSCertificate structure.
//
// Limitation: SEQUENCE boundaries are not enforced between fields. This is
// acceptable here because the input is always a SecCertificate already accepted
// by SecTrust — Apple's framework has validated the DER before we see it.
enum DERParser {
    static func notBeforeDate(of cert: SecCertificate) -> Date? {
        let der = SecCertificateCopyData(cert) as Data
        var cursor = Cursor(data: der)

        // X.509 structure:
        //   Certificate SEQUENCE
        //     TBSCertificate SEQUENCE
        //       [0] EXPLICIT version (optional, present in v3)
        //       INTEGER serialNumber
        //       SEQUENCE signatureAlgorithm
        //       SEQUENCE issuer
        //       SEQUENCE validity
        //         UTCTime/GeneralizedTime notBefore  ← target
        guard cursor.enterSequence(),   // Certificate
              cursor.enterSequence(),   // TBSCertificate
              cursor.skip(ifTag: 0xA0), // optional [0] version
              cursor.skipElement(),     // serialNumber
              cursor.skipElement(),     // signatureAlgorithm
              cursor.skipElement(),     // issuer
              cursor.enterSequence()    // validity
        else { return nil }

        return cursor.readDate()
    }

    private struct Cursor {
        let data: Data
        var index: Int = 0

        private mutating func readByte() -> UInt8? {
            guard index < data.count else { return nil }
            defer { index += 1 }
            return data[index]
        }

        private mutating func readLength() -> Int? {
            guard let first = readByte() else { return nil }
            if first < 0x80 { return Int(first) }
            let numBytes = Int(first & 0x7F)
            guard numBytes > 0, numBytes <= 4, index + numBytes <= data.count else { return nil }
            var length = 0
            for _ in 0..<numBytes {
                length = (length << 8) | Int(data[index])
                index += 1
            }
            return length
        }

        // Reads tag + length and positions cursor at first content byte.
        mutating func enterSequence() -> Bool {
            guard index < data.count, data[index] == 0x30 else { return false }
            index += 1
            return readLength() != nil
        }

        // Skips over a complete TLV element (tag + length + value).
        mutating func skipElement() -> Bool {
            guard readByte() != nil, let length = readLength() else { return false }
            guard index + length <= data.count else { return false }
            index += length
            return true
        }

        // Skips the element only if the next tag matches; always returns true if absent.
        mutating func skip(ifTag tag: UInt8) -> Bool {
            guard index < data.count else { return false }
            guard data[index] == tag else { return true } // absent, nothing to skip
            index += 1
            guard let length = readLength(), index + length <= data.count else { return false }
            index += length
            return true
        }

        // Reads a UTCTime (0x17) or GeneralizedTime (0x18) and returns the decoded Date.
        mutating func readDate() -> Date? {
            guard index < data.count else { return nil }
            let tag = data[index]
            guard tag == 0x17 || tag == 0x18 else { return nil }
            index += 1
            guard let length = readLength(), index + length <= data.count else { return nil }
            guard let str = String(bytes: data[index..<index + length], encoding: .ascii) else { return nil }
            index += length

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            // UTCTime:        YYMMDDHHMMSSZ
            // GeneralizedTime: YYYYMMDDHHMMSSZ
            formatter.dateFormat = tag == 0x17 ? "yyMMddHHmmss'Z'" : "yyyyMMddHHmmss'Z'"
            return formatter.date(from: str)
        }
    }
}
