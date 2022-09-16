//
//  WidgetStartShoppingView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import Combine

private class StartShoppingViewModel: ObservableObject {
    @Published var widget: WidgetButton?

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetStartShopping) {
        Snabble.shared.checkInManager.shopPublisher
            .sink { [weak self] shop in
                if shop != nil {
                    self?.widget = WidgetButton(
                        id: "Snabble.DynamicView.StartShopping.button",
                        text: "Snabble.DynamicView.StartShopping.button",
                        foregroundColorSource: "onAccent",
                        backgroundColorSource: "accent"
                    )
                } else {
                    self?.widget = nil
                }
            }
            .store(in: &cancellables)
    }
}

public struct WidgetStartShoppingView: View {
    let widget: WidgetStartShopping
    let action: (WidgetStartShopping) -> Void

    @ObservedObject private var viewModel: StartShoppingViewModel

    init(widget: WidgetStartShopping, action: @escaping (WidgetStartShopping) -> Void) {
        self.widget = widget
        self.action = action
        self.viewModel = StartShoppingViewModel(widget: widget)
    }

    public var body: some View {
        if let widget = viewModel.widget {
            WidgetButtonView(widget: widget) { _ in
                action(self.widget)
            }
        }
    }
}
