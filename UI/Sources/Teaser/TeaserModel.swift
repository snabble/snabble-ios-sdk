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
    private var imageCache: [String: UIImage] = [:]

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

    public func loadImage(from urlString: String) async -> UIImage? {
        if let cachedImage = imageCache[urlString] {
            return cachedImage
        }
        
        guard let projectId = shop?.projectId,
              let project = Snabble.shared.project(for: projectId) else {
            return nil
        }
        
        let fullUrlString = "\(Snabble.shared.environment.apiURLString)\(urlString)"
        
        return await withCheckedContinuation { continuation in
            project.fetchImage(urlString: fullUrlString) { [weak self] image in
                if let image = image {
                    self?.imageCache[urlString] = image
                }
                continuation.resume(returning: image)
            }
        }
    }

}
