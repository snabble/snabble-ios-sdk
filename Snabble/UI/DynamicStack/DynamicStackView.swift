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
        EmptyView()
    }
}
