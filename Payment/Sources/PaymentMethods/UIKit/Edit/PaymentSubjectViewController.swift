//
//  PaymentSubjectViewController.swift
//  
//
//  Created by Uwe Tilemann on 03.07.23.
//

import Foundation
import UIKit
import SwiftUI

/// A UIViewController wrapping SwiftUI's PaymentSubjectView
public final class PaymentSubjectViewController: UIHostingController<PaymentSubjectView> {
    public var viewModel: PaymentSubjectViewModel {
        rootView.viewModel
    }
    
    public init() {
        super.init(rootView: PaymentSubjectView(viewModel: PaymentSubjectViewModel()))
        view.backgroundColor = .clear
   }

    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
