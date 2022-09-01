//
//  WidgetInformationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public struct WidgetInformationView: View {
    let widget: WidgetInformation
    @ObservedObject var viewModel: DynamicStackViewModel

    public var body: some View {
        HStack {
            widget.image
            Text(widget.text)
        }
        .onTapGesture {
            viewModel.actionPublisher.send(widget)
        }
    }
}
