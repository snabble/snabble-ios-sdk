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
