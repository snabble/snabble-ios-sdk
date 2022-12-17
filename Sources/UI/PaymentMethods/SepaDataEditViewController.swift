//
//  SepaDataEditViewController.swift
//  
//
//  Created by Uwe Tilemann on 21.11.22.
//

import UIKit
import SwiftUI

/// A UIViewController wrapping SwiftUI's DynamicStackView
open class SepaDataEditViewController: UIHostingController<SepaDataView> {
    public var viewModel: SepaDataModel {
        rootView.model
    }
    /// Creates and returns an dynamic stack  view controller with the specified viewModel
    /// - Parameter viewModel: A view model that specifies the details to be shown. Default value is `.default`
    public init(viewModel: SepaDataModel) {
        super.init(rootView: SepaDataView(model: viewModel))
    }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
