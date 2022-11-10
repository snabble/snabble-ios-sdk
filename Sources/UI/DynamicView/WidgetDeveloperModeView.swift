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
        showDisclosure: true
    )
    @Published public private(set) var isEnabled: Bool = false

    override init() {
        self.isEnabled = DeveloperMode.isEnabled
    }
}

public struct WidgetDeveloperModeView: View {
    let widget: WidgetDeveloperMode
    let action: (Widget) -> Void

    @ObservedObject private var viewModel: DeveloperModeViewModel

    init(widget: WidgetDeveloperMode, action: @escaping (Widget) -> Void) {
        self.widget = widget
        self.action = action
        self.viewModel = .init()
    }

    public var body: some View {
        if viewModel.isEnabled {
            WidgetTextView(widget: viewModel.widget)
                .onTapGesture {
                    action(viewModel.widget)
                }
        } else {
            EmptyView()
        }
    }
}
