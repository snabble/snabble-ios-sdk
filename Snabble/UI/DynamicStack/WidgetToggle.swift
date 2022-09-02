//
//  WidgetToggle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetToggleView: View {
    var widget: WidgetToggle
    @ObservedObject var viewModel: DynamicStackViewModel
    @State private var toggleValue = false
    
    public var body: some View {
        HStack {
            Toggle(Asset.localizedString(forKey: widget.text), isOn: $toggleValue)
        }
    }
}
