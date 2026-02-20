//
//  WidgetDeveloperMode.swift
//
//  Created by Andreas Osberghaus on 2022-11-10.
//

import SwiftUI
import Combine

@Observable
public class DeveloperModeViewModel: NSObject {
    public private(set) var widget = WidgetText(
        id: "io.snabble.developerMode",
        text: "Profile.developerMode",
        showDisclosure: false
    )
    public private(set) var isEnabled: Bool = false

    override init() {
        self.isEnabled = DeveloperMode.isEnabled
    }
}

public struct WidgetDeveloperModeView: View {
    let widget: WidgetDeveloperMode

    private var developerModel: DeveloperModeViewModel

    init(widget: WidgetDeveloperMode) {
        self.widget = widget
        self.developerModel = .init()
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
