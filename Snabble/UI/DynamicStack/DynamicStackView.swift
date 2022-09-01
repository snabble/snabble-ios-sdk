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
        ScrollView {
            VStack(alignment: .center) {
                ForEach(viewModel.widgets, id: \.id) { widget in
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
            }
            .padding(16)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .background(viewModel.configuration.image, alignment: .top)
    }
}
