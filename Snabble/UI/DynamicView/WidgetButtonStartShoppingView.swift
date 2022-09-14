//
//  WidgetButtonStartShoppingView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import Combine

private class ButtonStartShoppingViewModel: ObservableObject {
    @Published var widget: WidgetButton?

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetSnabble) {
        Snabble.shared.checkInManager.shopPublisher
            .sink { [weak self] shop in
                if shop != nil {
                    self?.widget = WidgetButton(
                        id: widget.id,
                        text: "Start Shopping",
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
        if let widget = viewModel.widget {
            WidgetButtonView(widget: widget) { _ in
                action(self.widget)
            }
        }
    }
}
