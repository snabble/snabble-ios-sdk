//
//  WidgetCustomerCard.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 15.09.22.
//

import Foundation
import SwiftUI
import Combine

private class CustomerCardViewModel: ObservableObject {
    @Published var widget: WidgetInformation?

    private let baseWidget: Widget

    private var cancellables = Set<AnyCancellable>()

    init(widget: WidgetSnabble) {
        self.baseWidget = widget

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
        if project?.customerCards != nil {
            widget = WidgetInformation(
                id: baseWidget.id,
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
    let widget: WidgetSnabble
    let configuration: DynamicViewConfiguration

    @ObservedObject private var viewModel: CustomerCardViewModel

    init(widget: WidgetSnabble, configuration: DynamicViewConfiguration) {
        self.widget = widget
        self.configuration = configuration
        self.viewModel = CustomerCardViewModel(widget: widget)
    }

    public var body: some View {
        if let widget = viewModel.widget {
            WidgetInformationView(
                widget: widget,
                shadowRadius: configuration.shadowRadius
            )
        }
    }
}
