//
//  WidgetDeveloperMode.swift
//
//  Created by Andreas Osberghaus on 2022-11-10.
//

import SwiftUI
import Combine

public class DeveloperModeViewModel: NSObject, ObservableObject {
    @Published public private(set) var widgets: [Widget] = []
    @Published public private(set) var isEnabled: Bool = false

    override init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "io.snabble.developerMode")
    }
}

public struct WidgetDeveloperModeView: View {
    let widget: WidgetDeveloperMode

    @ObservedObject private var viewModel: DeveloperModeViewModel

    init(widget: WidgetDeveloperMode) {
        self.widget = widget
        self.viewModel = .init()
    }

    public var body: some View {
        

        Text("Entwickler Modus")
    }
}
