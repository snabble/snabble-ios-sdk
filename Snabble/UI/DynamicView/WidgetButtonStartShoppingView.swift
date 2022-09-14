//
//  WidgetButtonStartShoppingView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI

private class ButtonStartShoppingViewModel: ObservableObject {
    @Published var widget: WidgetButton

    init(widget: WidgetSnabble) {
        self.widget = WidgetButton(
            id: widget.id,
            text: "Start Shopping",
            foregroundColorSource: "onAccent",
            backgroundColorSource: "accent"
        )
    }
}

public struct WidgetButtonStartShoppingView: View {
    let widget: WidgetSnabble
    let action: (WidgetSnabble) -> Void

    @ObservedObject private var viewModel: ButtonStartShoppingViewModel

    init(widget: WidgetSnabble, action: @escaping (WidgetSnabble) -> Void) {
        self.widget = widget
        self.action = action
        self.viewModel = ButtonStartShoppingViewModel(widget: widget)
    }

    public var body: some View {
        WidgetButtonView(widget: viewModel.widget) { _ in
            action(widget)
        }
    }
}
