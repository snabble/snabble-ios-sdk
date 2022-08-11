//
//  SelectionSheetAppearance.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

protocol SelectionSheetAppearance {
    var backgroundColor: UIColor { get }

    var titleFont: UIFont { get }
    var titleColor: UIColor { get }

    var messageFont: UIFont { get }
    var messageColor: UIColor { get }

    var actionTitleFont: UIFont { get }
    var actionTitleColor: UIColor { get }

    var actionSubtitleFont: UIFont { get }
    var actionSubtitleColor: UIColor { get }

    var cancelButtonFont: UIFont { get }
    var cancelButtonColor: UIColor { get }
}

extension SelectionSheetAppearance {
    var backgroundColor: UIColor {
        UIColor { traitCollection in
           traitCollection.userInterfaceStyle == .dark ? .secondarySystemBackground : Assets.Color.systemBackground()
       }
    }

    var titleFont: UIFont { .preferredFont(forTextStyle: .headline) }
    var titleColor: UIColor { Assets.Color.label() }

    var messageFont: UIFont { .preferredFont(forTextStyle: .body) }
    var messageColor: UIColor { Assets.Color.label() }

    var actionTitleFont: UIFont { .preferredFont(forTextStyle: .title3) }
    var actionTitleColor: UIColor { Assets.Color.label() }

    var actionSubtitleFont: UIFont { .preferredFont(forTextStyle: .body) }
    var actionSubtitleColor: UIColor { Assets.Color.label() }

    var cancelButtonFont: UIFont { .preferredFont(forTextStyle: .title3, weight: .semibold) }
    var cancelButtonColor: UIColor { Assets.Color.label() }
}

struct DefaultSelectionSheetAppearance: SelectionSheetAppearance { }
