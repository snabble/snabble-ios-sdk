//
//  SelectionSheetAction.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

struct SelectionSheetAction {
    typealias ActionHandler = (SelectionSheetAction) -> Void

    let title: String
    let subtitle: String?
    let image: UIImage?
    let handler: ActionHandler?

    init(title: String,
         subtitle: String? = nil,
         image: UIImage? = nil,
         handler: ActionHandler? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.handler = handler
    }
}
