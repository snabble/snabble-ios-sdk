//
//  WidgetAllStoresView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 14.09.22.
//

import Foundation
import SwiftUI
import Combine

import SnabbleCore

@Observable
private class AllStoresViewModel {
    var widget: WidgetButton?

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetAllStores) {
        Snabble.shared.checkInManager.shopPublisher
            .sink { [weak self] shop in
                if shop != nil {
                    self?.widget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.AllStores.button"
                    )
                } else {
                    self?.widget = WidgetButton(
                        id: widget.id,
                        text: "Snabble.DynamicView.AllStores.button",
                        foregroundColorSource: "onProjectPrimary",
                        backgroundColorSource: "projectPrimary"
                    )
                }
            }
            .store(in: &cancellables)
    }
}

public struct WidgetAllStoresView: View {
    let widget: WidgetAllStores
    let action: (WidgetAllStores) -> Void

    @State private var viewModel: AllStoresViewModel

    init(widget: WidgetAllStores, action: @escaping (WidgetAllStores) -> Void) {
        self.widget = widget
        self.action = action
        self._viewModel = State(initialValue: AllStoresViewModel(widget: widget))
    }

    public var body: some View {
        if let widget = viewModel.widget {
            WidgetButtonView(widget: widget) { _ in
                action(self.widget)
            }
        }
    }
}
