//
//  AESCrypt.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import CommonCrypto

public struct AESCrypt {
    private let key: Data
    private let iv: Data

    public init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
    }

    public func encrypt(_ data: Data) -> Data? {
        return crypt(input: data, operation: CCOperation(kCCEncrypt))
    }

    public func decrypt(_ encrypted: Data) -> Data? {
        return crypt(input: encrypted, operation: CCOperation(kCCDecrypt))
    }

    private func crypt(input: Data, operation: CCOperation) -> Data? {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var status = CCCryptorStatus(kCCSuccess)

        input.withUnsafeBytes { encryptedBytes in
            self.iv.withUnsafeBytes { ivBytes in
                self.key.withUnsafeBytes { keyBytes in
                    status = CCCrypt(operation,
                        CCAlgorithm(kCCAlgorithmAES128),            // algorithm
                        CCOptions(kCCOptionPKCS7Padding),           // options
                        keyBytes.baseAddress,                       // key
                        self.key.count,                             // key length
                        ivBytes.baseAddress,                        // iv
                        encryptedBytes.baseAddress,                 // dataIn
                        input.count,                                // dataIn Length
                        &outBytes,                                  // dataOut
                        outBytes.count,                             // dataOut Available
                        &outLength)                                 // dataOut Moved
                }
            }
        }

        guard status == kCCSuccess else {
            NSLog("crypt failed: \(status)")
            return nil
        }
        return Data(bytes: outBytes, count: outLength)
    }

    public static func decryptString(_ string: String, _ keyBytes: String, _ ivBytes: String) -> String? {
        guard
            let keyBytes = Data(base64Encoded: keyBytes, options: .ignoreUnknownCharacters),
            let ivBytes = Data(base64Encoded: ivBytes, options: .ignoreUnknownCharacters)
        else {
            return nil
        }
        
        let aes = AESCrypt(key: keyBytes, iv: ivBytes)
        
        guard
            let bytes = Data(base64Encoded: string, options: .ignoreUnknownCharacters),
            let decrypted = aes.decrypt(bytes),
            let str = String(bytes: decrypted, encoding: .utf8)
        else {
            return nil
        }

        return str
    }
}
