//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-14.
//

import Foundation
import SnabblePayNetwork

extension SnabblePay: NetworkManagerDelegate {
    public func networkManager(_ networkManager: NetworkManager, didUpdateCredentials credentials: SnabblePayNetwork.Credentials?) {
        delegate?.snabblePay(self, didUpdateCredentials: credentials?.toModel())
    }
}
