//
//  WidgetCustomerCard.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 15.09.22.
//

import Foundation
import SwiftUI
import SnabbleCore

public struct WidgetCustomerCardView: View {
    let widget: WidgetCustomerCard
    let configuration: DynamicViewConfiguration
    let action: (Widget) -> Void

    @State private var informationWidget: WidgetInformation?

    public var body: some View {
        Group {
            if let informationWidget {
                WidgetInformationView(
                    widget: informationWidget,
                    configuration: configuration
                )
                .onTapGesture {
                    action(informationWidget)
                }
            }
        }
        .task(id: widget.projectId) {
            if let projectId = widget.projectId,
               let project = Snabble.shared.project(for: projectId) {
                updateWidget(for: project)
            } else {
                for await shop in Snabble.shared.checkInManager.shopStream {
                    updateWidget(for: shop?.project)
                }
            }
        }
    }

    private func updateWidget(for project: Project?) {
        // CustomerCardInfo is empty {} so it's needed to check `accepted`.
        if !(project?.customerCards?.accepted?.isEmpty ?? true) {
            informationWidget = WidgetInformation(
                id: "Snabble.DynamicView.CustomerCard.information",
                text: "Snabble.DynamicView.customerCard",
                imageSource: "Snabble.DynamicView.customerCard",
                hideable: false
            )
        } else {
            informationWidget = nil
        }
    }
}
