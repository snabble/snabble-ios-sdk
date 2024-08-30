//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation
import SnabbleNetwork

public extension SnabbleUser.AppUser {
    init?(appUser: SnabbleNetwork.AppUser?) {
        guard let appUser else { return nil }
        self.init(id: appUser.id, secret: appUser.secret)
    }
}

public extension SnabbleNetwork.AppUser {
    init?(appUser: SnabbleUser.AppUser?) {
        guard let appUser else { return nil }
        self.init(id: appUser.id, secret: appUser.secret)
    }
}
