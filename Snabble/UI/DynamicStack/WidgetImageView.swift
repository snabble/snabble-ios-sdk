//
//  WidgetImageView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public struct WidgetImageView: View {
    let widget: WidgetImage
    @ObservedObject var viewModel: DynamicStackViewModel

    public var body: some View {
        HStack {
            Spacer()
            widget.image
                .onTapGesture {
                    viewModel.actionPublisher.send(widget)
                }
            Spacer()
        }
    }
}
