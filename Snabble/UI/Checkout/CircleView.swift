//
//  CircleView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit
import QuartzCore

public class CircleView: UIView {

    public var circleColor: UIColor? = .clear {
        didSet {
            shapeLayer?.fillColor = circleColor?.cgColor
        }
    }

    override public class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    private var shapeLayer: CAShapeLayer? {
        layer as? CAShapeLayer
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        shapeLayer?.fillColor = circleColor?.cgColor

        clipsToBounds = false
        layer.masksToBounds = false
    }

    override public func layoutSubviews() {
        updateShapeLayerFrame()
    }

    func updateShapeLayerFrame() {
        let squareSize = min(frame.size.width, frame.size.height)
        var rect = CGRect(origin: CGPoint.zero, size: CGSize(width: squareSize, height: squareSize))
        rect.origin.x = floor((frame.size.width - squareSize) * 0.5)
        rect.origin.y = floor((frame.size.height - squareSize) * 0.5)
        shapeLayer?.path = UIBezierPath(ovalIn: rect).cgPath
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import AutoLayout_Helper

@available(iOS 13, *)
struct CircleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview {
                let view = CircleView(frame: .zero)
                view.circleColor = .red
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
