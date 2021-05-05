//
//  BarcodeDetectorOverlay.swift
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

    public var reticleVisible = true {
        didSet {
            updateReticleVisibility()
        }
    }

    public init(appearance: BarcodeDetectorAppearance) {
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

    private func updateReticleVisibility() {
        self.reticle.isHidden = !reticleVisible
        self.reticleDimmingLayer.isHidden = !reticleVisible
        self.fullDimmingLayer.isHidden = reticleVisible
    }
}
