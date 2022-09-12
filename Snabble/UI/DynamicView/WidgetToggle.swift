//
//  WidgetToggle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetToggleView: View {
    var widget: WidgetToggle
    @ObservedObject var viewModel: DynamicViewModel
    @AppStorage var value: Bool

    init(widget: WidgetToggle, viewModel: DynamicViewModel) {
        self.widget = widget
        self.viewModel = viewModel

        self._value = AppStorage(
            wrappedValue: UserDefaults.standard.bool(forKey: widget.key), widget.key,
            store: .standard
        )
    }
    
    public var body: some View {
        HStack {
            Toggle(Asset.localizedString(forKey: widget.text), isOn: $value)
        }
        .onChange(of: value) { newState in
            viewModel.actionPublisher.send(
                .init(
                    widget: widget,
                    userInfo: [widget.key: newState]
                )
            )
        }
    }
}
