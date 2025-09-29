//
//  AlertStyle.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import SDCAlertView

public final class SnabbleAlertStyle: AlertVisualStyle, @unchecked Sendable {
    override public init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: alertStyle)

        self.normalTextColor = .label

        self.actionSheetPreferredFont = self.alertNormalFont
        self.actionSheetNormalFont = self.alertPreferredFont
    }
}

extension AlertVisualStyle {
    public static let snabbleAlert = SnabbleAlertStyle(alertStyle: .alert)
    public static let snabbleActionSheet = SnabbleAlertStyle(alertStyle: .actionSheet)
}
