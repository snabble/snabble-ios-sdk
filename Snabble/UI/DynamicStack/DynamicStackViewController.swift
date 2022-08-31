//
//  DynamicStackViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import UIKit
import SwiftUI

public class DynamicStackViewController: UIHostingController<DynamicStackView> {
    public var viewModel: DynamicStackViewModel {
        rootView.viewModel
    }

    public init(viewModel: DynamicStackViewModel) {
        let rootView = DynamicStackView(viewModel: viewModel)
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
