//
//  WidgetButtonStoresView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import Combine

private class ButtonStoresViewModel: ObservableObject {
    @Published var widget: WidgetButton?

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetSnabble) {
        Snabble.shared.checkInManager.shopPublisher
            .sink { [weak self] shop in
                if shop != nil {
                    self?.widget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.Button.stores"
                    )
                } else {
                    self?.widget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.Button.stores",
                        foregroundColorSource: "onAccent",
                        backgroundColorSource: "accent"
                    )
                }
            }
            .store(in: &cancellables)
    }
}

public struct WidgetButtonStoresView: View {
    let widget: WidgetSnabble
    let action: (WidgetSnabble) -> Void

    @ObservedObject private var viewModel: ButtonStoresViewModel

    init(widget: WidgetSnabble, action: @escaping (WidgetSnabble) -> Void) {
        self.widget = widget
        self.action = action
        self.viewModel = ButtonStoresViewModel(widget: widget)
    }

    public var body: some View {
        if let widget = viewModel.widget {
            WidgetButtonView(widget: widget) { _ in
                action(self.widget)
            }
        }
    }
}
