//
//  TeaserModel.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import SwiftUI

import SnabbleCore

@Observable
@MainActor
public final class TeaserModel {
    private(set) var shop: Shop?
    
    public var teasers: [CustomizationConfig.Teaser] = []
    
    public init(shop: Shop? = nil) {
        load(for: shop)
    }

    public func load(for shop: Shop?) {
        self.shop = shop

        guard let projectId = shop?.projectId,
              let project = Snabble.shared.project(for: projectId),
              let config = project.customizationConfig else {
            teasers = []
            return
        }
        teasers = config.validTeasers
    }
}
