//
//  WidgetSectionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct WidgetSectionView: View {
    var widget: WidgetSection
    @Environment(DynamicViewModel.self) private var viewModel

    public var body: some View {
        Section(header: Text(keyed: widget.header)) {
            WidgetContainer(widgets: widget.items)
        }
    }
}
