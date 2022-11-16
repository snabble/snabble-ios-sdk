//
//  WidgetDeveloperMode.swift
//
//  Created by Andreas Osberghaus on 2022-11-10.
//

import SwiftUI
import Combine

public class DeveloperModeViewModel: NSObject, ObservableObject {
    public private(set) var widget = WidgetText(
        id: "io.snabble.developerMode",
        text: "Profile.developerMode",
        showDisclosure: false
    )
    @Published public private(set) var isEnabled: Bool = false

    override init() {
        self.isEnabled = DeveloperMode.isEnabled
    }
}

public struct WidgetDeveloperModeView: View {
    let widget: WidgetDeveloperMode

    @ObservedObject private var developerModel: DeveloperModeViewModel
    @ObservedObject private var viewModel: DynamicViewModel

    init(widget: WidgetDeveloperMode, viewModel: DynamicViewModel) {
        self.widget = widget
        self.viewModel = viewModel
        self.developerModel = .init()
    }

    public var body: some View {
        if self.developerModel.isEnabled {
            NavigationLink(destination: {
                List {
                    WidgetContainer(viewModel: self.viewModel, widgets: widget.items)
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
