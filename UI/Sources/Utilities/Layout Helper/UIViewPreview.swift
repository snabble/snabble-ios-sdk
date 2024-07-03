//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 18.10.22.
//

import Foundation
import UIKit
import SwiftUI

// MARK: SwiftUI Preview
@available(iOS 13.0, *)
public struct UIViewPreview<View>: UIViewRepresentable where View: UIView {
    public let view: View

    public init(_ builder: @escaping () -> View) {
        view = builder()
    }

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UIView {
        view
    }

    // swiftlint:disable:next no_empty_block
    public func updateUIView(_ view: UIView, context: Context) {}
}
