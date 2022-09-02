//
//  WidgetSectionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetSectionView: View {
    var widget: WidgetSection
    @ObservedObject var viewModel: DynamicStackViewModel

    public var body: some View {
        List {
            Section(header: Text(keyed: widget.header)) {
                WidgetContainer(viewModel: viewModel, widgets: widget.items)
            }
        }.listStyle(.grouped)
    }
}
