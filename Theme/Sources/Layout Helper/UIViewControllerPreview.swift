//
//  UIViewControllerPreview.swift
//  
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public struct UIViewControllerPreview<ViewController>: UIViewControllerRepresentable where ViewController: UIViewController {
    public let viewController: ViewController

    public init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    // MARK: - UIViewControllerRepresentable
    public func makeUIViewController(context: Context) -> ViewController {
        viewController
    }

    public func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<UIViewControllerPreview<ViewController>>) {}
}
#endif
