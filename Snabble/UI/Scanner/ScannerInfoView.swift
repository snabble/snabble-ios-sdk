//
//  ScannerInfoView.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

protocol ScannerInfoDelegate: class {
    func close()
}

final class ScannerInfoView: DesignableView {
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var textLabel: UILabel!

    weak var delegate: ScannerInfoDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.view.backgroundColor = .clear
        self.addCornersAndShadow(backgroundColor: .white, cornerRadius: 8)

        let str = "Snabble.Scanner.introText".localized()

        let html = """
            <style type="text/css">
            * { font-family: apple-system,sans-serif; font-size: 17px; text-align: center; }
            </style>
        """ + str

        guard
            let data = html.data(using: String.Encoding.utf16, allowLossyConversion: false),
            let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        else {
            return
        }

        self.textLabel.attributedText = attributedString
        self.textLabel.sizeToFit()

        self.startButton.backgroundColor = SnabbleUI.appearance.primaryColor
        self.startButton.tintColor = SnabbleUI.appearance.secondaryColor
        self.startButton.makeRoundedButton()
        self.startButton.setTitle("Snabble.Scanner.start".localized(), for: .normal)
    }
    

    @IBAction private func startButtonTapped(_ button: UIButton) {
        self.delegate?.close()
    }

}
