//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation
import SnabbleNetwork

public extension SnabbleUser.AppUser {
    func toDTO() -> SnabbleNetwork.AppUserDTO {
        SnabbleNetwork.AppUserDTO(id: id, secret: secret)
    }
    
    static func fromDTO(_ appUser: SnabbleNetwork.AppUserDTO) -> Self {
        .init(id: appUser.id, secret: appUser.secret)
    }
}
