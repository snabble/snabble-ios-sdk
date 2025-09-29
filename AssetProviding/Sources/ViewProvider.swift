//
//  ViewProvider.swift
//  
//
//  Created by Uwe Tilemann on 03.02.23.
//

import SwiftUI

@propertyWrapper
public struct ViewProvider {
    public enum Name: String {
        case ratingAccessory
        case successCheckout
        case receiptsEmpty
        case paymentsEmpty
    }
    private let key: ViewProvider.Name

    public init(_ key: ViewProvider.Name) {
        self.key = key
    }
    public init(wrappedValue: @escaping () -> any View, _ key: ViewProvider.Name) {
        self.key = key
        ViewProviderStore.register(view: wrappedValue, for: key)
    }
    public var isAvailable: Bool {
        ViewProviderStore.hasView(for: key)
    }
    public var wrappedValue: AnyView {
        ViewProviderStore.makeView(key: key)
    }
}

public enum ViewProviderStore {
    nonisolated(unsafe) public static var providers: [String: () -> any View] = [:]

    public static func register(view: @escaping () -> any View, for key: ViewProvider.Name) {
        providers[key.rawValue] = view
    }

    public static func hasView(for key: ViewProvider.Name) -> Bool {
        return providers[key.rawValue] != nil
    }
    
    public static func makeView(key: ViewProvider.Name) -> AnyView {
        if let view = providers[key.rawValue] {
            return AnyView(view())
        } else {
            return AnyView(EmptyView())
        }
    }
}
