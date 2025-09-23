//
//  WidgetCustomerCard.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 15.09.22.
//

import Foundation
import SwiftUI
import Combine

import SnabbleCore

@Observable
private class CustomerCardViewModel {
    var widget: WidgetInformation?

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetCustomerCard) {
        if let projectId = widget.projectId,
           let project = Snabble.shared.project(for: projectId) {
            self.widget(for: project)
        } else {
            Snabble.shared.checkInManager.shopPublisher
                .sink { [weak self] shop in
                    self?.widget(for: shop?.project)
                }
                .store(in: &cancellables)
        }
    }

    private func widget(for project: Project?) {
        // CustomerCardInfo is empty {} so it's needed to check `accepted`.
        if !(project?.customerCards?.accepted?.isEmpty ?? true) {
            widget = WidgetInformation(
                id: "Snabble.DynamicView.CustomerCard.information",
                text: "Snabble.DynamicView.customerCard",
                imageSource: "Snabble.DynamicView.customerCard",
                hideable: false
            )
        } else {
            widget = nil
        }
    }
}

public struct WidgetCustomerCardView: View {
    let widget: WidgetCustomerCard
    let configuration: DynamicViewConfiguration
    let action: (Widget) -> Void

    @State private var viewModel: CustomerCardViewModel

    init(widget: WidgetCustomerCard, configuration: DynamicViewConfiguration, action: @escaping (Widget) -> Void) {
        self.widget = widget
        self.configuration = configuration
        self.action = action

        self._viewModel = State(initialValue: CustomerCardViewModel(widget: widget))
    }

    public var body: some View {
        if let widget = viewModel.widget {
            WidgetInformationView(
                widget: widget,
                configuration: configuration
            ).onTapGesture {
                action(widget)
            }
        }
    }
}
