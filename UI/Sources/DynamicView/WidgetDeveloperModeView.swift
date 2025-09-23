//
//  WidgetDeveloperMode.swift
//
//  Created by Andreas Osberghaus on 2022-11-10.
//

import SwiftUI

@Observable
public class DeveloperModeViewModel {
    public private(set) var widget = WidgetText(
        id: "io.snabble.developerMode",
        text: "Profile.developerMode",
        showDisclosure: false
    )
    public private(set) var isEnabled: Bool = false

    init() {
        self.isEnabled = DeveloperMode.isEnabled
    }
}

public struct WidgetDeveloperModeView: View {
    let widget: WidgetDeveloperMode

    @State private var developerModel = DeveloperModeViewModel()
    @Environment(DynamicViewModel.self) private var viewModel

    init(widget: WidgetDeveloperMode) {
        self.widget = widget
    }

    public var body: some View {
        if self.developerModel.isEnabled {
            NavigationLink(destination: {
                List {
                    WidgetContainer(widgets: widget.items)
                }
                .listStyle(.grouped)
            }) {
                WidgetTextView(widget: developerModel.widget)
            }
        } else {
            EmptyView()
        }
    }
}
