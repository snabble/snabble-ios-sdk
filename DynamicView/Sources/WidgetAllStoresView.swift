//
//  WidgetAllStoresView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import SnabbleCore

public struct WidgetAllStoresView: View {
    let widget: WidgetAllStores
    let action: (WidgetAllStores) -> Void

    @State private var buttonWidget: WidgetButton?

    public var body: some View {
        Group {
            if let buttonWidget {
                WidgetButtonView(widget: buttonWidget) { _ in
                    action(widget)
                }
            }
        }
        .task {
            for await shop in Snabble.shared.checkInManager.shopStream {
                if shop != nil {
                    buttonWidget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.AllStores.button"
                    )
                } else {
                    buttonWidget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.AllStores.button",
                        foregroundColorSource: "onProjectPrimary",
                        backgroundColorSource: "projectPrimary"
                    )
                }
            }
        }
    }
}
