//
//  EANView.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

//  loosely based on code from https://github.com/astrokin/EAN13BarcodeGenerator
//
//  the encoding is described in detail on
//  https://en.wikipedia.org/wiki/International_Article_Number_(EAN) and
//  https://de.wikipedia.org/wiki/European_Article_Number
//

import UIKit
import SnabbleCore

public final class EANView: UIView {
    /// the color to show the barcode's bars. default is black
    public var barColor: UIColor = .black

    /// the color to show the barcode's digits. default is black
    public var digitsColor: UIColor = .black

    /// show the numeric value of the barcode at the bottom. default is true
    public var showDigits = true

    /// line width of a single "1" bit
    public var scale: Int = 2

    /// the barcode to display
    public var barcode: String? {
        didSet {
            self.bits = EAN.encode(barcode ?? "")
            self.updateLabels()
            self.setNeedsDisplay()
        }
    }

    /// the bits we need to render
    private var bits: EAN.Bits?

    // labels for the numeric display
    private var firstDigitLabel: UILabel?
    private var leftDigitsLabel: UILabel?
    private var rightDigitsLabel: UILabel?

    private var leftMargin: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let bgColor = self.backgroundColor ?? .systemBackground
        let bottomPadding = CGFloat(showDigits ? self.scale * 3 : 0)

        bgColor.setFill()
        ctx.fill(rect)

        if let bits = self.bits {
            let barcodeBits = bits.count
            let calculatedWidth = CGFloat(scale * barcodeBits)
            leftMargin = (rect.size.width - calculatedWidth) / 2
            if self.firstDigitLabel == nil && self.showDigits {
                self.createLabels()
                self.updateLabels()
            }
            ctx.beginPath()
            for idx in 0 ..< bits.count {
                let color = bits[idx] == 1 ? barColor : bgColor
                color.set()
                let x = idx == 0 ? leftMargin : leftMargin + CGFloat(scale * idx)
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: self.bounds.size.height - bottomPadding))
                ctx.setLineWidth(CGFloat(scale))
                ctx.strokePath()
            }
            bgColor.set()
            ctx.move(to: CGPoint(x: CGFloat(scale * barcodeBits), y: 0.0))
            ctx.addLine(to: CGPoint(x: CGFloat(scale * barcodeBits), y: self.bounds.size.height - bottomPadding))
            ctx.strokePath()
        } else {
            let attrs = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                NSAttributedString.Key.foregroundColor: UIColor.systemRed
            ]
            let str = NSAttributedString(string: "Invalid Barcode", attributes: attrs)
            let stringSize = str.size()
            str.draw(at: CGPoint(x: (rect.size.width - stringSize.width) / 2,
                                 y: (rect.size.height - stringSize.height) / 2))
        }
    }

    private func updateLabels() {
        guard self.showDigits, let barcode = self.barcode else {
            return
        }

        switch barcode.count {
        case 13:
            self.firstDigitLabel?.text = self.barcodeSubstringAt(start: 0, length: 1)
            self.leftDigitsLabel?.text = self.barcodeSubstringAt(start: 1, length: 6)
            self.rightDigitsLabel?.text = self.barcodeSubstringAt(start: 7, length: 6)
        case 8:
            self.firstDigitLabel?.text = nil
            self.leftDigitsLabel?.text = self.barcodeSubstringAt(start: 0, length: 4)
            self.rightDigitsLabel?.text = self.barcodeSubstringAt(start: 4, length: 4)
        default:
            break
        }
    }

    private func createLabels() {
        let charWidth = 7
        let labelWidth = self.labelWidth()

        self.firstDigitLabel = self.createLabel(width: charWidth, offset: 0, value: " ")
        self.addSubview(self.firstDigitLabel!)

        self.leftDigitsLabel = self.createLabel(width: charWidth * labelWidth, offset: 12, value: " ")
        self.addSubview(self.leftDigitsLabel!)

        let rightOffset = 12 + charWidth * labelWidth + 4
        self.rightDigitsLabel = self.createLabel(width: charWidth * labelWidth, offset: rightOffset, value: " ")
        self.addSubview(self.rightDigitsLabel!)
    }

    private func labelWidth() -> Int {
        switch self.barcode?.count {
        case 13: return 6
        case 8: return 4
        default: return 0
        }
    }

    private func createLabel(width: Int, offset: Int, value: String) -> UILabel {
        let digitHeight = 7

        let frame = CGRect(x: Int(leftMargin) + scale * offset,
                           y: Int(self.bounds.size.height) - (scale * digitHeight),
                           width: scale * width,
                           height: scale * digitHeight)
        let label = UILabel(frame: frame)
        label.backgroundColor = self.backgroundColor ?? .systemBackground
        label.textColor = self.digitsColor
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: CGFloat(scale * (digitHeight - 1)), weight: .medium)
        label.text = value

        return label
    }

    private func barcodeSubstringAt(start: Int, length: Int) -> String {
        guard let barcode = self.barcode, start < barcode.count && start + length <= barcode.count else {
            return ""
        }

        let startIndex = barcode.index(barcode.startIndex, offsetBy: start)
        let endIndex = barcode.index(barcode.startIndex, offsetBy: start + length)
        let subs = barcode[ startIndex ..< endIndex ]
        return String(subs)
    }
}
