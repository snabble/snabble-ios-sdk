//
//  TeaserDetailController.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import UIKit
import SwiftUI

import SnabbleCore

public final class TeaserDetailController: UIHostingController<TeaserDetailView> {
    public init(model: TeaserModel, teaser: CustomizationConfig.Teaser, image: UIImage?) {
        super.init(rootView: TeaserDetailView(model: model, teaser: teaser, image: image))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
