//
//  BuiltinBarcodeDetector.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public class BarcodeDetectorOverlay: UIView {
    /// the visible reticle
    public let reticle = UIView()
    /// the container for the buttons
    public let bottomBar = UIView()
    /// the "enter barcode manually" button
    public let enterButton = UIButton(type: .custom)
    /// the "toggle the torch" button
    public let torchButton = UIButton(type: .custom)
    /// the "go to shopping cart" button
    public let cartButton = UIButton(type: .system)
    /// the frame for showing where the barcode was scanned
    public let frameView = UIView()

    public let reticleDimmingLayer = CAShapeLayer()
    public let fullDimmingLayer = CAShapeLayer()

    private let appearance: BarcodeDetectorAppearance

    init(appearance: BarcodeDetectorAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false

        reticle.translatesAutoresizingMaskIntoConstraints = false
        reticle.backgroundColor = .clear
        reticle.layer.borderColor = appearance.reticleBorderColor.cgColor
        reticle.layer.borderWidth = 1 / UIScreen.main.scale
        reticle.layer.cornerRadius = appearance.reticleCornerRadius

        let bottomOffset: CGFloat = appearance.bottomBarHidden ? 0 : 64
        self.addSubview(reticle)
        NSLayoutConstraint.activate([
            reticle.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            reticle.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            reticle.heightAnchor.constraint(equalToConstant: appearance.reticleHeight),
            reticle.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -bottomOffset / 2)
        ])

        reticleDimmingLayer.fillRule = .evenOdd
        reticleDimmingLayer.fillColor = appearance.dimmingColor.cgColor

        self.layer.addSublayer(reticleDimmingLayer)

        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.isHidden = appearance.bottomBarHidden
        self.addSubview(bottomBar)
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            bottomBar.heightAnchor.constraint(equalToConstant: 48),
            bottomBar.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ])

        enterButton.translatesAutoresizingMaskIntoConstraints = false
        enterButton.setImage(appearance.enterButtonImage, for: .normal)
        enterButton.layer.cornerRadius = 8
        enterButton.layer.borderColor = appearance.borderColor.cgColor
        enterButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(enterButton)
        NSLayoutConstraint.activate([
            enterButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            enterButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            enterButton.heightAnchor.constraint(equalToConstant: 48),
            enterButton.widthAnchor.constraint(equalToConstant: 48)
        ])

        torchButton.translatesAutoresizingMaskIntoConstraints = false
        torchButton.setImage(appearance.torchButtonImage, for: .normal)
        torchButton.layer.cornerRadius = 8
        torchButton.layer.borderColor = appearance.borderColor.cgColor
        torchButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(torchButton)
        NSLayoutConstraint.activate([
            torchButton.leadingAnchor.constraint(equalTo: enterButton.trailingAnchor, constant: 16),
            torchButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            torchButton.heightAnchor.constraint(equalToConstant: 48),
            torchButton.widthAnchor.constraint(equalToConstant: 48)
        ])

        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.layer.cornerRadius = 8
        cartButton.backgroundColor = appearance.backgroundColor
        cartButton.setTitleColor(appearance.textColor, for: .normal)
        cartButton.setTitle("", for: .normal)
        cartButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        bottomBar.addSubview(cartButton)

        NSLayoutConstraint.activate([
            cartButton.leadingAnchor.constraint(equalTo: torchButton.trailingAnchor, constant: 16),
            cartButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            cartButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            cartButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        frameView.backgroundColor = .clear
        frameView.layer.borderColor = UIColor.lightGray.cgColor
        frameView.layer.borderWidth = 1 / UIScreen.main.scale
        frameView.layer.cornerRadius = 3
        self.addSubview(frameView)

        fullDimmingLayer.fillColor = appearance.dimmingColor.cgColor
        fullDimmingLayer.isHidden = true
        self.layer.addSublayer(fullDimmingLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        let overlayPath = UIBezierPath(rect: self.bounds)

        let transparentPath = UIBezierPath(roundedRect: reticle.frame, cornerRadius: appearance.reticleCornerRadius)
        overlayPath.append(transparentPath)
        reticleDimmingLayer.path = overlayPath.cgPath

        fullDimmingLayer.path = UIBezierPath(rect: self.bounds).cgPath
    }
}

/// creates the standard overlay decoration for the product scanner
@available(*, deprecated, message: "use BarcodeDetectorOverlay instead")
public struct BarcodeDetectorDecoration {
    /// the visible reticle
    public let reticle: UIView
    /// the container for the buttons
    public let bottomBar: UIView
    /// the "enter barcode manually" button
    public let enterButton: UIButton
    /// the "toggle the torch" button
    public let torchButton: UIButton
    /// the "go to shopping cart" button
    public let cartButton: UIButton
    /// the frame for showing where the barcode was scanned
    public let frameView: UIView

    public let reticleDimmingLayer: CAShapeLayer
    public let fullDimmingLayer: CAShapeLayer

    /// add the standard overlay decoration for the product scanner
    ///
    /// - Parameters:
    ///   - cameraPreview: the view to add the decoration to. Note that the decoration is added based on that view's frame/bounds,
    ///     and therefore this should only be called after the view has been laid out.
    ///   - appearance: the appearance to use
    /// - Returns: a `BarcodeDetectorDecoration` instance that contains all views and buttons that were created
    // swiftlint:disable:next function_body_length
    public static func add(to cameraPreview: UIView, appearance: BarcodeDetectorAppearance) -> BarcodeDetectorDecoration {
        // the reticle itself
        let reticle = UIView(frame: .zero)
        reticle.backgroundColor = .clear
        reticle.layer.borderColor = appearance.reticleBorderColor.cgColor
        reticle.layer.borderWidth = 1 / UIScreen.main.scale
        reticle.layer.cornerRadius = appearance.reticleCornerRadius

        let bottomOffset: CGFloat = appearance.bottomBarHidden ? 0 : 64
        let reticleFrame = CGRect(x: 16,
                                  y: (cameraPreview.frame.height - bottomOffset - appearance.reticleHeight) / 2,
                                  width: cameraPreview.frame.width - 32,
                                  height: appearance.reticleHeight)
        reticle.frame = reticleFrame
        cameraPreview.addSubview(reticle)

        // a dimming layer with a hole for the reticle
        let overlayPath = UIBezierPath(rect: cameraPreview.bounds)
        let transparentPath = UIBezierPath(roundedRect: reticleFrame, cornerRadius: appearance.reticleCornerRadius)
        overlayPath.append(transparentPath)

        let borderLayer = CAShapeLayer()
        borderLayer.path = overlayPath.cgPath
        borderLayer.fillRule = .evenOdd
        borderLayer.fillColor = appearance.dimmingColor.cgColor
        cameraPreview.layer.addSublayer(borderLayer)

        // add the bottom bar
        let bottomBarFrame = CGRect(x: 16,
                                    y: cameraPreview.frame.height - 64,
                                    width: cameraPreview.frame.width - 32,
                                    height: 48)
        let bottomBar = UIView(frame: bottomBarFrame)
        bottomBar.isHidden = appearance.bottomBarHidden
        cameraPreview.addSubview(bottomBar)

        // a dimming layer that covers the whole preview
        let fullDimmingLayer = CAShapeLayer()
        let path = UIBezierPath(rect: cameraPreview.bounds)
        fullDimmingLayer.path = path.cgPath
        fullDimmingLayer.fillColor = appearance.dimmingColor.cgColor
        // fullDimmingLayer.zPosition = -0.5
        fullDimmingLayer.isHidden = true
        cameraPreview.layer.addSublayer(fullDimmingLayer)

        // barcode entry button
        let enterButton = UIButton(type: .custom)
        enterButton.frame = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        enterButton.setImage(appearance.enterButtonImage, for: .normal)
        enterButton.layer.cornerRadius = 8
        enterButton.layer.borderColor = appearance.borderColor.cgColor
        enterButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(enterButton)

        // torch button
        let torchButton = UIButton(type: .custom)
        torchButton.frame = CGRect(origin: CGPoint(x: 48 + 16, y: 0), size: CGSize(width: 48, height: 48))
        torchButton.setImage(appearance.torchButtonImage, for: .normal)
        torchButton.layer.cornerRadius = 8
        torchButton.layer.borderColor = appearance.borderColor.cgColor
        torchButton.layer.borderWidth = 1.0 / UIScreen.main.scale
        bottomBar.addSubview(torchButton)

        // cart button
        let cartButton = UIButton(type: .system)
        let cartWidth = cameraPreview.frame.width - 2 * 48 - 4 * 16
        cartButton.frame = CGRect(origin: CGPoint(x: 48 + 16 + 48 + 16, y: 0), size: CGSize(width: cartWidth, height: 48))
        cartButton.layer.cornerRadius = 8
        cartButton.backgroundColor = appearance.backgroundColor
        cartButton.setTitleColor(appearance.textColor, for: .normal)
        cartButton.setTitle("", for: .normal)
        cartButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        bottomBar.addSubview(cartButton)

        // frame view
        let frameView = UIView(frame: .zero)
        frameView.backgroundColor = .clear
        frameView.layer.borderColor = UIColor.lightGray.cgColor
        frameView.layer.borderWidth = 1 / UIScreen.main.scale
        frameView.layer.cornerRadius = 3
        cameraPreview.addSubview(frameView)

        return BarcodeDetectorDecoration(reticle: reticle,
                                         bottomBar: bottomBar,
                                         enterButton: enterButton,
                                         torchButton: torchButton,
                                         cartButton: cartButton,
                                         frameView: frameView,
                                         reticleDimmingLayer: borderLayer,
                                         fullDimmingLayer: fullDimmingLayer)
    }

    public func removeFromSuperview() {
        self.reticle.removeFromSuperview()
        self.bottomBar.removeFromSuperview()
        self.enterButton.removeFromSuperview()
        self.torchButton.removeFromSuperview()
        self.cartButton.removeFromSuperview()
        self.frameView.removeFromSuperview()
        self.reticleDimmingLayer.removeFromSuperlayer()
        self.fullDimmingLayer.removeFromSuperlayer()
    }
}
