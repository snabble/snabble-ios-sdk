//
//  CheckoutRatingView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 05.10.21.
//

import Foundation
import UIKit

public final class CheckoutRatingView: UIView {
    public enum State {
        case initial
        case finished
    }
    public private(set) weak var textLabel: UILabel?
    public private(set) weak var detailTextLabel: UILabel?

    public private(set) weak var leftButton: UIButton?
    public private(set) weak var middleButton: UIButton?
    public private(set) weak var rightButton: UIButton?

    private weak var buttonStackView: UIStackView?

    public var state: State = .initial {
        didSet {
            switch state {
            case .initial:
                detailTextLabel?.isHidden = true
                buttonStackView?.isHidden = false
            case .finished:
                detailTextLabel?.isHidden = false
                buttonStackView?.isHidden = true
            }
        }
    }

    override public init(frame: CGRect) {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .systemFont(ofSize: 17)
        textLabel.numberOfLines = 1
        textLabel.minimumScaleFactor = 13.0 / 17.0
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.lineBreakMode = .byTruncatingMiddle
        textLabel.textAlignment = .center
        textLabel.text = L10n.PaymentDone.Rating.title

        let detailTextLabel = UILabel()
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        detailTextLabel.font = .systemFont(ofSize: 17)
        detailTextLabel.numberOfLines = 1
        detailTextLabel.minimumScaleFactor = 13.0 / 17.0
        detailTextLabel.adjustsFontSizeToFitWidth = true
        detailTextLabel.lineBreakMode = .byTruncatingMiddle
        detailTextLabel.textAlignment = .center
        detailTextLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        detailTextLabel.text = L10n.PaymentDone.Rating.thanks
        detailTextLabel.isHidden = true

        let leftButton = UIButton(type: .custom)
        leftButton.setImage(UIImage.fromBundle("SnabbleSDK/emoji-1"), for: .normal)

        let middleButton = UIButton(type: .custom)
        middleButton.setImage(UIImage.fromBundle("SnabbleSDK/emoji-2"), for: .normal)

        let rightButton = UIButton(type: .custom)
        rightButton.setImage(UIImage.fromBundle("SnabbleSDK/emoji-3"), for: .normal)

        let buttonStackView = UIStackView(arrangedSubviews: [leftButton, middleButton, rightButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 22
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fillEqually

        super.init(frame: frame)

        addSubview(textLabel)
        addSubview(detailTextLabel)
        addSubview(buttonStackView)

        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.buttonStackView = buttonStackView

        self.leftButton = leftButton
        self.middleButton = middleButton
        self.rightButton = rightButton

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            detailTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: detailTextLabel.bottomAnchor),

            buttonStackView.topAnchor.constraint(equalTo: detailTextLabel.topAnchor),
            detailTextLabel.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor),

            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: textLabel.trailingAnchor),

            detailTextLabel.centerXAnchor.constraint(equalTo: textLabel.centerXAnchor),
            detailTextLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: detailTextLabel.trailingAnchor),

            buttonStackView.centerXAnchor.constraint(equalTo: textLabel.centerXAnchor),
            buttonStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: buttonStackView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import AutoLayout_Helper

@available(iOS 13, *)
public struct CheckoutRatingView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            UIViewPreview {
                let view = CheckoutRatingView()
                view.state = .finished
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutRatingView()
                view.state = .initial
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
