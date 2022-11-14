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

extension WidgetMultiValue.WidgetValue {
    public func contains(string: String?) -> Bool {
        guard string != nil else {
            return false
        }
        guard self.id != string else {
            return true
        }
        if let last = self.id.components(separatedBy: ".").last, last == string {
            return true
        }
        return false
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
                        Text(keyed: value.text)
                        Spacer()
                        if value.contains(string: viewModel.selectedValue) {
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
            .listStyle(.grouped)
        }) {
            Text(keyed: widget.text)
        }
    }
}
