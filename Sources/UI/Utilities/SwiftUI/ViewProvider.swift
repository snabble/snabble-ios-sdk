//
//  ViewProvider.swift
//  
//
//  Created by Uwe Tilemann on 03.02.23.
//

import SwiftUI

@propertyWrapper
public struct ViewProvider {
    private let key: String

    public init(_ key: String) {
        self.key = key
    }
    public var isAvailable: Bool {
        ViewProviderStore.hasView(for: key)
    }
    public var wrappedValue: AnyView {
        ViewProviderStore.makeView(key: key)
    }
}

public enum ViewProviderStore {
    public static var providers: [String: () -> any View] = [:]
    public static var types: [String: any View.Type] = [:]

    public static func register(view: @escaping () -> any View, for key: String) {
        providers[key] = view
    }
    public static func register(type: any View.Type, for key: String) {
        types[key] = type
    }
    public static func hasView(for key: String) -> Bool {
        return providers[key] != nil
    }
    
    public static func makeView(key: String) -> AnyView {
        if let view = providers[key] {
            return AnyView(view())
        } else {
            return AnyView(EmptyView())
        }
    }
}
