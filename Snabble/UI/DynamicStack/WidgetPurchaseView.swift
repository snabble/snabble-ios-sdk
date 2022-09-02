//
//  WidgetPurchaseView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public struct WidgetPurchaseView: View {
    let widget: WidgetPurchase
    @ObservedObject var viewModel: DynamicViewModel

    public var body: some View {
        Text(widget.projectId?.description ?? "no project ID")
    }
}
