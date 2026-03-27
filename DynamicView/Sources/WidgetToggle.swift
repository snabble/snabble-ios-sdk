//
//  WidgetToggle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI
import SnabbleAssetProviding

public struct WidgetToggleView: View {
    var widget: WidgetToggle
    var action: (DynamicAction) -> Void
    @AppStorage var value: Bool

    init(widget: WidgetToggle, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.action = action

        self._value = AppStorage(
            wrappedValue: UserDefaults.standard.bool(forKey: widget.key), widget.key,
            store: .standard
        )
    }
    
    public var body: some View {
        HStack {
            Toggle(Asset.localizedString(forKey: widget.text), isOn: $value)
        }
        .onChange(of: value) { _, newState in
            action(.init(
                widget: widget,
                userInfo: [widget.key: newState]
            ))
        }
    }
}
