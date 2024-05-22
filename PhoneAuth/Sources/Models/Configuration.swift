//
//  Configuration.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-03.
//

import Foundation
import SnabbleNetwork

public struct Configuration {
    public let appId: String
    public let appSecret: String
    public let domain: Domain

    public init(appId: String, appSecret: String, domain: Domain) {
        self.appId = appId
        self.appSecret = appSecret
        self.domain = domain
    }

}

extension Configuration: Equatable {}

extension Configuration {
    func toDTO() -> SnabbleNetwork.Configuration {
        SnabbleNetwork.Configuration(
            appId: appId,
            appSecret: appSecret,
            domain: domain.toDTO()
        )
    }
}

extension SnabbleNetwork.Configuration {
    func fromDTO() -> Configuration {
        Configuration(
            appId: appId,
            appSecret: appSecret,
            domain: domain.fromDTO()
        )
    }
}
