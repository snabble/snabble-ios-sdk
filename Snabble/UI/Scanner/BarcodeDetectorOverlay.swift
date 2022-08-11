//
//  BarcodeDetectorOverlay.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public enum BarcodeDetectorArea {
    // a rectangle, centered vertically and about 30% of the view's height
    case rectangle
    // a square, centered vertically
    case square
}

public final class BarcodeDetectorOverlay: UIView {
    /// the frame for showing where the barcode was scanned
    private let frameView = UIView()

    private let barcodeOverlay = UIImageView()

    // our virtual reticle - used so that we can easily position it using auto layout
    // but always invisible except for debugging
    private let reticle = UIView()
    private let debugReticle = false

    private var overlayYCenter: NSLayoutConstraint?
    private var frameTimer: Timer?

    public var centerYOffset: CGFloat = 0 {
        didSet {
            overlayYCenter?.constant = centerYOffset
        }
    }

    public var roi: CGRect {
        return reticle.frame
    }

    public init(detectorArea: BarcodeDetectorArea) {
        super.init(frame: .zero)

        barcodeOverlay.translatesAutoresizingMaskIntoConstraints = false
        barcodeOverlay.image = Asset.SnabbleSDK.barcodeOverlay.image
        addSubview(barcodeOverlay)

        NSLayoutConstraint.activate([
            barcodeOverlay.centerXAnchor.constraint(equalTo: centerXAnchor),
            barcodeOverlay.centerYAnchor.constraint(equalTo: centerYAnchor).usingVariable(&overlayYCenter),

            barcodeOverlay.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: barcodeOverlay.bottomAnchor, constant: 16),

            barcodeOverlay.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(greaterThanOrEqualTo: barcodeOverlay.trailingAnchor, constant: 16)
        ])

        translatesAutoresizingMaskIntoConstraints = false

        reticle.translatesAutoresizingMaskIntoConstraints = false
        if Snabble.debugMode && debugReticle {
            reticle.layer.borderColor = Assets.Color.systemGreen().cgColor
            reticle.layer.cornerRadius = 5
            reticle.layer.borderWidth = 1 / UIScreen.main.scale
            reticle.layer.masksToBounds = true
        }
        addSubview(reticle)

        let reticleHeight: NSLayoutConstraint
        switch detectorArea {
        case .rectangle:
            reticleHeight = reticle.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3, constant: 0)
        case .square:
            reticleHeight = reticle.heightAnchor.constraint(equalTo: reticle.widthAnchor, multiplier: 1, constant: 0)
        }

        NSLayoutConstraint.activate([
            reticle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: reticle.trailingAnchor, constant: 16),

            reticle.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: reticle.bottomAnchor, constant: 16),

            reticleHeight.usingPriority(.defaultHigh + 1),

            reticle.centerYAnchor.constraint(equalTo: barcodeOverlay.centerYAnchor)
        ])

        frameView.backgroundColor = Assets.Color.clear()
        frameView.layer.borderColor = Assets.Color.border().cgColor
        frameView.layer.borderWidth = 1 / UIScreen.main.scale
        frameView.layer.cornerRadius = 3

        addSubview(frameView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showFrameView(at frame: CGRect) {
        UIView.animate(withDuration: 0.25) {
            self.frameView.frame = frame
        }

        frameView.frame = frame
        frameView.isHidden = false

        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.frameView.isHidden = true
        }
    }
}
