//
//  WidgetStartShoppingView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import SnabbleCore

public struct WidgetStartShoppingView: View {
    let widget: WidgetStartShopping
    let action: (WidgetStartShopping) -> Void

    @State private var shoppingButton: WidgetButton?

    init(widget: WidgetStartShopping, action: @escaping (WidgetStartShopping) -> Void) {
        self.widget = widget
        self.action = action
    }

    public var body: some View {
        Group {
            if let shoppingButton {
                WidgetButtonView(widget: shoppingButton) { _ in
                    action(self.widget)
                }
            }
        }
        .task {
            for await shop in Snabble.shared.checkInManager.shopStream {
                if shop != nil {
                    shoppingButton = WidgetButton(
                        id: "Snabble.DynamicView.StartShopping.button",
                        text: "Snabble.DynamicView.StartShopping.button",
                        foregroundColorSource: "onProjectPrimary",
                        backgroundColorSource: "projectPrimary"
                    )
                } else {
                    shoppingButton = nil
                }
            }
        }
    }
}
