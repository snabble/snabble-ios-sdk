//
//  SelectionSheetAction.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

struct SelectionSheetAction {
    typealias ActionHandler = (SelectionSheetAction) -> Void

    let title: String
    let subTitle: String?
    let image: UIImage?
    let handler: ActionHandler?

    init(title: String,
         subTitle: String? = nil,
         image: UIImage? = nil,
         handler: ActionHandler? = nil) {
        self.title = title
        self.subTitle = subTitle
        self.image = image
        self.handler = handler
    }
}
