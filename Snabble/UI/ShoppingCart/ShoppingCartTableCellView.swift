//
//  ShoppingCartTableCellView.swift
//  Snabble
//
//  Created by Anastasia Mishur on 8.04.22.
//

protocol ShoppingCardCellViewDelegate: AnyObject {
    func plusButtonTapped()
    func minusButtonTapped()
}

final class ShoppingCartTableCellView: UIView {
    public weak var imageView: ImageView?
    public weak var badgeView: BadgeView?

    public weak var nameView: NameView?

    public weak var weightView: WeightView?
    public weak var entryView: EntryView?
    public weak var quantityView: QuantityView?

    weak var delegate: ShoppingCardCellViewDelegate?

    override init(frame: CGRect) {
        let imageView = ImageView(frame: .zero)
        let badgeView = BadgeView(frame: .zero)

        let nameView = NameView(frame: .zero)

        let weightView = WeightView(frame: .zero)
        let entryView = EntryView(frame: .zero)
        let quantityView = QuantityView(frame: .zero)

        let stackView = UIStackView(arrangedSubviews: [imageView, badgeView, nameView, weightView, entryView, quantityView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill

        self.imageView = imageView
        self.badgeView = badgeView

        self.nameView = nameView

        self.weightView = weightView
        self.entryView = entryView
        self.quantityView = quantityView

        super.init(frame: frame)

        addSubview(stackView)

        quantityView.plusButton?.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)
        quantityView.minusButton?.addTarget(self, action: #selector(minusButtonTapped(_:)), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            imageView.widthAnchor.constraint(equalToConstant: 48)
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func plusButtonTapped(_ sender: Any) {
        delegate?.plusButtonTapped()
    }

    @objc private func minusButtonTapped(_ sender: Any) {
        delegate?.minusButtonTapped()
    }

    public func updateBadgeText(withText text: String?) {
        badgeView?.badgeLabel?.text = text
        badgeView?.badgeLabel?.isHidden = text == nil

        imageView?.badgeView?.badgeLabel?.text = text
        imageView?.badgeView?.isHidden = text == nil
    }

    public func updateBadgeColor(withColor color: UIColor?) {
        badgeView?.backgroundView?.backgroundColor = color
        imageView?.badgeView?.backgroundView?.backgroundColor = color
    }

    public func updateQuantityText(withText text: String?) {
        quantityView?.quantityLabel?.text = text
        weightView?.quantityLabel?.text = text
        entryView?.quantityTextField?.text = text
    }

    public func updateUnitsText(withText text: String?) {
        entryView?.unitLabel?.text = text
        weightView?.unitLabel?.text = text
    }

    public func updateLeftDisplay(withMode mode: LeftDisplay) {
        [imageView, badgeView].forEach { $0?.isHidden = true }
        switch mode {
        case .none:
            break
        case .badge:
            badgeView?.isHidden = false
        case .image, .emptyImage:
            imageView?.isHidden = false
        }
    }

    public func updateRightDisplay(withMode mode: RightDisplay) {
        [quantityView, weightView, entryView].forEach { $0?.isHidden = true }
        switch mode {
        case .none:
            break
        case .buttons:
            quantityView?.isHidden = false
        case .weightDisplay:
            weightView?.isHidden = false
        case .weightEntry:
            entryView?.isHidden = false
        }
    }
}

extension ShoppingCartTableCellView {
    final class ImageView: UIView {
        private(set) weak var badgeView: BadgeView?

        private(set) weak var imageBackgroundView: UIView?
        private(set) weak var imageView: UIImageView?
        private(set) weak var activityIndicatorView: UIActivityIndicatorView?

        override init(frame: CGRect) {
            let badgeView = BadgeView(frame: .zero)
            badgeView.translatesAutoresizingMaskIntoConstraints = false

            let imageBackgroundView = UIView()
            imageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            imageBackgroundView.layer.cornerRadius = 4
            imageBackgroundView.layer.masksToBounds = true
            imageBackgroundView.backgroundColor = Asset.Color.systemBackground()

            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 4
            imageView.layer.masksToBounds = true

            let activityIndicatorView = UIActivityIndicatorView(style: .medium)
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            activityIndicatorView.hidesWhenStopped = true

            super.init(frame: frame)

            addSubview(imageBackgroundView)
            addSubview(imageView)
            addSubview(badgeView)
            addSubview(activityIndicatorView)

            self.imageBackgroundView = imageBackgroundView
            self.imageView = imageView
            self.badgeView = badgeView
            self.activityIndicatorView = activityIndicatorView

            NSLayoutConstraint.activate([
                activityIndicatorView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                activityIndicatorView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),

                imageView.topAnchor.constraint(equalTo: imageBackgroundView.topAnchor),
                imageBackgroundView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

                imageView.leadingAnchor.constraint(equalTo: imageBackgroundView.leadingAnchor),
                imageBackgroundView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

                imageBackgroundView.heightAnchor.constraint(equalToConstant: 32),
                imageBackgroundView.widthAnchor.constraint(equalToConstant: 32),

                imageBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
                imageBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),

                imageBackgroundView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
                bottomAnchor.constraint(greaterThanOrEqualTo: imageBackgroundView.bottomAnchor, constant: 8),

                imageBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
                trailingAnchor.constraint(greaterThanOrEqualTo: imageBackgroundView.trailingAnchor, constant: 8),

                badgeView.topAnchor.constraint(equalTo: imageBackgroundView.topAnchor),
                badgeView.heightAnchor.constraint(equalToConstant: 16),
                badgeView.widthAnchor.constraint(equalToConstant: 16),
                badgeView.trailingAnchor.constraint(equalTo: imageBackgroundView.leadingAnchor, constant: 8)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class BadgeView: UIView {
        private(set) weak var backgroundView: UIView?
        private(set) weak var badgeLabel: UILabel?

        override init(frame: CGRect) {
            let backgroundView = UIView()
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.layer.cornerRadius = 4
            backgroundView.layer.masksToBounds = true

            let badgeLabel = UILabel()
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            badgeLabel.font = UIFont.systemFont(ofSize: 11)
            badgeLabel.textColor = Asset.Color.onLabel()
            badgeLabel.textAlignment = .center
            badgeLabel.layer.cornerRadius = 4
            badgeLabel.layer.masksToBounds = true

            super.init(frame: frame)

            addSubview(backgroundView)
            addSubview(badgeLabel)

            self.badgeLabel = badgeLabel
            self.backgroundView = backgroundView

            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 2),
                backgroundView.bottomAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 2),

                badgeLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
                backgroundView.trailingAnchor.constraint(equalTo: badgeLabel.trailingAnchor),

                backgroundView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
                bottomAnchor.constraint(greaterThanOrEqualTo: backgroundView.bottomAnchor),
                backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),

                backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class NameView: UIView {
        private(set) weak var nameLabel: UILabel?
        private(set) weak var priceLabel: UILabel?

        override init(frame: CGRect) {
            let nameLabel = UILabel()
            nameLabel.font = Asset.preferredFont(forTextStyle: .subheadline)
            nameLabel.adjustsFontForContentSizeCategory = true
            nameLabel.textColor = Asset.Color.label()
            nameLabel.textAlignment = .natural
            nameLabel.numberOfLines = 0

            let priceLabel = UILabel()
            priceLabel.font = Asset.preferredFont(forTextStyle: .footnote)
            priceLabel.adjustsFontForContentSizeCategory = true
            priceLabel.textColor = Asset.Color.systemGray()
            priceLabel.textAlignment = .natural

            let stackView = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical

            super.init(frame: frame)

            addSubview(stackView)

            self.nameLabel = nameLabel
            self.priceLabel = priceLabel

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
                bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 8),

                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class WeightView: UIView {
        private(set) weak var unitLabel: UILabel?
        private(set) weak var quantityLabel: UILabel?

        override init(frame: CGRect) {
            let quantityLabel = UILabel()
            quantityLabel.translatesAutoresizingMaskIntoConstraints = false
            quantityLabel.font = Asset.preferredFont(forTextStyle: .footnote, weight: .semibold)
            quantityLabel.adjustsFontForContentSizeCategory = true
            quantityLabel.textColor = Asset.Color.label()
            quantityLabel.textAlignment = .right

            let unitLabel = UILabel()
            unitLabel.translatesAutoresizingMaskIntoConstraints = false
            unitLabel.font = Asset.preferredFont(forTextStyle: .footnote, weight: .semibold)
            unitLabel.adjustsFontForContentSizeCategory = true
            unitLabel.textColor = Asset.Color.label()
            unitLabel.textAlignment = .center
            unitLabel.setContentHuggingPriority(.required, for: .horizontal)

            super.init(frame: frame)

            addSubview(unitLabel)
            addSubview(quantityLabel)

            self.unitLabel = unitLabel
            self.quantityLabel = quantityLabel

            NSLayoutConstraint.activate([
                quantityLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
                bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: quantityLabel.bottomAnchor, multiplier: 1),
                quantityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

                unitLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
                bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: unitLabel.bottomAnchor, multiplier: 1),
                unitLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

                quantityLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                unitLabel.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor, constant: 8),
                trailingAnchor.constraint(equalTo: unitLabel.trailingAnchor),

                quantityLabel.widthAnchor.constraint(equalToConstant: 34),
                unitLabel.widthAnchor.constraint(equalToConstant: 18)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class EntryView: UIView {
        private(set) weak var unitLabel: UILabel?
        private(set) weak var quantityTextField: UITextField?

        override init(frame: CGRect) {
            let quantityTextField = UITextField()
            quantityTextField.translatesAutoresizingMaskIntoConstraints = false
            quantityTextField.textColor = Asset.Color.label()
            quantityTextField.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            quantityTextField.textAlignment = .right
            quantityTextField.borderStyle = .roundedRect
            quantityTextField.backgroundColor = Asset.Color.secondarySystemBackground()
            quantityTextField.keyboardType = .numberPad
            quantityTextField.minimumFontSize = 17
            quantityTextField.adjustsFontSizeToFitWidth = true

            let unitLabel = UILabel()
            unitLabel.translatesAutoresizingMaskIntoConstraints = false
            unitLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            unitLabel.textColor = Asset.Color.label()
            unitLabel.textAlignment = .center
            unitLabel.setContentHuggingPriority(.required, for: .horizontal)

            super.init(frame: frame)

            addSubview(quantityTextField)
            addSubview(unitLabel)

            self.quantityTextField = quantityTextField
            self.unitLabel = unitLabel

            NSLayoutConstraint.activate([
                quantityTextField.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
                bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: quantityTextField.bottomAnchor, multiplier: 1),
                quantityTextField.centerYAnchor.constraint(equalTo: centerYAnchor),

                unitLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
                bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: unitLabel.bottomAnchor, multiplier: 1),
                unitLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

                quantityTextField.widthAnchor.constraint(equalToConstant: 80),

                quantityTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
                unitLabel.leadingAnchor.constraint(equalTo: quantityTextField.trailingAnchor, constant: 8),
                trailingAnchor.constraint(equalTo: unitLabel.trailingAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class QuantityView: UIView {
        private(set) weak var minusButton: UIButton?
        private(set) weak var plusButton: UIButton?
        private(set) weak var quantityLabel: UILabel?

        override init(frame: CGRect) {
            let minusButton = UIButton(type: .custom)
            minusButton.translatesAutoresizingMaskIntoConstraints = false
            minusButton.setImage(Asset.image(named: "SnabbleSDK/icon-minus"), for: .normal)
            minusButton.makeBorderedButton()
            minusButton.backgroundColor = Asset.Color.secondarySystemBackground()

            let plusButton = UIButton(type: .custom)
            plusButton.translatesAutoresizingMaskIntoConstraints = false
            plusButton.setImage(Asset.image(named: "SnabbleSDK/icon-plus"), for: .normal)
            plusButton.makeBorderedButton()
            plusButton.backgroundColor = Asset.Color.secondarySystemBackground()

            let quantityLabel = UILabel()
            quantityLabel.translatesAutoresizingMaskIntoConstraints = false
            quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            quantityLabel.textColor = Asset.Color.label()
            quantityLabel.textAlignment = .center
            super.init(frame: frame)

            addSubview(minusButton)
            addSubview(plusButton)
            addSubview(quantityLabel)

            self.minusButton = minusButton
            self.plusButton = plusButton
            self.quantityLabel = quantityLabel

            NSLayoutConstraint.activate([
                minusButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
                bottomAnchor.constraint(greaterThanOrEqualTo: minusButton.bottomAnchor),
                minusButton.centerYAnchor.constraint(equalTo: centerYAnchor),

                plusButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
                bottomAnchor.constraint(greaterThanOrEqualTo: plusButton.bottomAnchor),
                plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),

                quantityLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
                bottomAnchor.constraint(greaterThanOrEqualTo: quantityLabel.bottomAnchor),
                quantityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

                minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                quantityLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor),
                plusButton.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor),
                trailingAnchor.constraint(equalTo: plusButton.trailingAnchor),

                minusButton.widthAnchor.constraint(equalToConstant: 32),
                minusButton.heightAnchor.constraint(equalToConstant: 32),

                plusButton.widthAnchor.constraint(equalTo: minusButton.widthAnchor),
                plusButton.heightAnchor.constraint(equalTo: minusButton.heightAnchor),

                quantityLabel.widthAnchor.constraint(equalToConstant: 34)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
