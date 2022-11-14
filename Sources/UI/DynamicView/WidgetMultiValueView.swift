//
//  WidgetMultiValueView.swift
//  
//
//  Created by Uwe Tilemann on 11.11.22.
//

import SwiftUI

public class MultiValueViewModel: ObservableObject {
    
    public var key: String {
        return widget.id
    }
    
    @Published var widget: WidgetMultiValue
    
    var selectedValue: String? {
        get {
            return UserDefaults.standard.string(forKey: key)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            objectWillChange.send()
        }
    }
    
    init(widget: WidgetMultiValue) {
        self.widget = widget
    }
}

public struct WidgetMultiValueView: View {
    var widget: WidgetMultiValue
    let action: (DynamicAction) -> Void
    @ObservedObject private var viewModel: MultiValueViewModel

    init(widget: WidgetMultiValue, action: @escaping (DynamicAction) -> Void) {
        self.widget = widget
        self.action = action

        self.viewModel = .init(widget: widget)
    }

    public var body: some View {
        NavigationLink(destination: {
            List {
                ForEach(widget.values, id: \.self) { value in
                    HStack(spacing: 0) {
                        Text(Asset.localizedString(forKey: value.text))
                        Spacer()
                        if value.id == viewModel.selectedValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedValue = value.id
                        action(.init(widget: widget, userInfo: ["model": viewModel, "value": value.id]))
                    }
                    
                }
            }
        }) {
            Text(keyed: widget.text)
        }
    }
}
