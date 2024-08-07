// The Swift Programming Language
// https://docs.swift.org/swift-book

import SnabblePhoneAuth
import SnabbleNetwork

public var networkConfiguration: SnabbleNetwork.Configuration = .init(appId: "app-123", appSecret: "secrect-123", domain: .testing)

extension NetworkManager {
    public convenience init() {
        self.init(configuration: networkConfiguration)
    }
    
    public static var shared: NetworkManager = {
        return NetworkManager()
    }()
}
