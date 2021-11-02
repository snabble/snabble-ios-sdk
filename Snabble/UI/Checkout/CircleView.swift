//
//  CircleView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit
import QuartzCore

class CircleView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        let squareSize = min(frame.size.width, frame.size.height)
        layer.cornerRadius = squareSize / 2
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import AutoLayout_Helper

@available(iOS 13, *)
public struct CircleView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            UIViewPreview {
                let view = CircleView(frame: .zero)
                view.backgroundColor = .red
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
