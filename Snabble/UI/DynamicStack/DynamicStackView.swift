//
//  DynamicStackView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import SwiftUI

public struct DynamicStackView: View {
    @ObservedObject public var viewModel: DynamicStackViewModel

    init(viewModel: DynamicStackViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List(viewModel.widgets, id: \.id) { widget in
            switch widget.type {
            case .text:
                EmptyView()
            case .image:
                EmptyView()
            case .button:
                EmptyView()
            case .information:
                EmptyView()
            case .purchases:
                EmptyView()
            }
        }
        .padding()
        .background(
            viewModel.configuration.image?
                .resizable()
        )
    }
}
