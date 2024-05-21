//
//  Configuration.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-03.
//

import Foundation

public struct Configuration {
    public let appId: String
    public let appSecret: String
    public let domain: Domain
    public let projectId: String?

    public init(appId: String, appSecret: String, domain: Domain, projectId: String? = nil) {
        self.appId = appId
        self.appSecret = appSecret
        self.domain = domain
        self.projectId = projectId
    }
}

extension Configuration: Equatable {}
