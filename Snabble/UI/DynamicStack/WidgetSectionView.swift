//
//  WidgetSectionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetSectionView: View {
    var widget: WidgetSection
    @ObservedObject var viewModel: DynamicViewModel

    public var body: some View {
        Section(header: Text(keyed: widget.header)) {
            WidgetContainer(viewModel: viewModel, widgets: widget.items)
        }
    }
}
