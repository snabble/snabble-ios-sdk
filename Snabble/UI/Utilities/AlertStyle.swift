//
//  AlertStyle.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import SDCAlertView

public final class SnabbleAlertStyle: AlertVisualStyle {
    override public init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: alertStyle)

        self.normalTextColor = .label

        self.alertNormalFont = UIFont.preferredFont(forTextStyle: .body)
        self.alertPreferredFont = UIFont.preferredFont(forTextStyle: .headline)

        self.actionSheetPreferredFont = self.alertNormalFont
        self.actionSheetNormalFont = self.alertPreferredFont
    }
}

extension AlertVisualStyle {
    public static var snabbleAlert: SnabbleAlertStyle { .init(alertStyle: .alert) }
    public static var snabbleActionSheet: SnabbleAlertStyle { .init(alertStyle: .actionSheet) }
}
