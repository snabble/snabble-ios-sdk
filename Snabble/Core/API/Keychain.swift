//
//  Keychain.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// a tiny and extremely simple keychain wrapper
//
// based on Apple's GenericKeychain sample:
// https://developer.apple.com/library/archive/samplecode/GenericKeychain/Introduction/Intro.html

#warning("remove this file")
struct unused__Keychain {
    private let service: String

    init(service: String) {
        self.service = service
    }

    // read-write access like a dictionary.
    // assigning `nil` to a key removes it
    subscript(_ key: String) -> String? {
        get { return self.get(key) }
        set { self.set(key, newValue) }
    }

    // same as assigning `nil`
    func remove(_ key: String) {
        let query = self.query(service, key)
        _ = SecItemDelete(query as CFDictionary)
    }

    private func get(_ key: String) -> String? {
        var query = self.query(service, key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard status == noErr else {
            return nil
        }

        guard
            let existingItem = queryResult as? [String: AnyObject],
            let data = existingItem[kSecValueData as String] as? Data,
            let str = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return str
    }

    private func set(_ key: String, _ value: String?) {
        guard let value = value else {
            return self.remove(key)
        }

        let data = value.data(using: .utf8)!

        if self.get(key) != nil {
            // update the existing item
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = data as AnyObject?

            let query = self.query(service, key)
            _ = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else {
            var newItem = self.query(service, key)
            newItem[kSecValueData as String] = data as AnyObject?

            // add the new item
            _ = SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    private func query(_ service: String, _ key: String) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject
        query[kSecAttrAccount as String] = key as AnyObject

        return query
    }
}

