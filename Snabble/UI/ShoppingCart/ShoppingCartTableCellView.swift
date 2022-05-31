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

final class BadgeView: UIView {
    private(set) weak var backgroundView: UIView?
    private(set) weak var badgeLabel: UILabel?

    override init(frame: CGRect) {
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        let badgeLabel = UILabel()
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = UIFont.systemFont(ofSize: 11)
        badgeLabel.textColor = .label.contrast
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 4
        badgeLabel.layer.masksToBounds = true

        super.init(frame: frame)

        addSubview(backgroundView)
        addSubview(badgeLabel)

        self.badgeLabel = badgeLabel
        self.backgroundView = backgroundView

        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 4),
            backgroundView.bottomAnchor.constraint(equalTo: badgeLabel.bottomAnchor, constant: 4),
            badgeLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),

            badgeLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 4),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 4),

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
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .natural
        nameLabel.numberOfLines = 0

        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        priceLabel.textColor = .systemGray
        priceLabel.textAlignment = .natural

        super.init(frame: frame)

        addSubview(nameLabel)
        addSubview(priceLabel)

        self.nameLabel = nameLabel
        self.priceLabel = priceLabel

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            bottomAnchor.constraint(equalTo: priceLabel.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: priceLabel.trailingAnchor)
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
        quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .right

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        unitLabel.textColor = .label
        unitLabel.textAlignment = .center

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
        quantityTextField.textColor = .label
        quantityTextField.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityTextField.textAlignment = .right
        quantityTextField.borderStyle = .roundedRect
        quantityTextField.backgroundColor = .secondarySystemBackground
        quantityTextField.keyboardType = .numberPad
        quantityTextField.minimumFontSize = 17
        quantityTextField.adjustsFontSizeToFitWidth = true

        let unitLabel = UILabel()
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        unitLabel.textColor = .label
        unitLabel.textAlignment = .center

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

            quantityTextField.widthAnchor.constraint(equalToConstant: 80).usingPriority(.defaultHigh),
            quantityTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

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
        minusButton.setImage(Asset.SnabbleSDK.iconMinus.image, for: .normal)
        minusButton.makeBorderedButton()
        minusButton.backgroundColor = .secondarySystemBackground

        let plusButton = UIButton(type: .custom)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.setImage(Asset.SnabbleSDK.iconPlus.image, for: .normal)
        plusButton.makeBorderedButton()
        plusButton.backgroundColor = .secondarySystemBackground

        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .center
        quantityLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
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

            quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),
            quantityLabel.widthAnchor.constraint(equalToConstant: 34).usingPriority(.defaultHigh)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ShoppingCartTableCellView: UIView {
    private weak var leftStackView: UIStackView?
    private weak var rightStackView: UIStackView?

    public weak var imageWrapper: UIView?
    public weak var imageBadge: UILabel?
    public weak var imageBackground: UIView?
    public weak var productImage: UIImageView?
    public weak var spinner: UIActivityIndicatorView?

    public weak var badgeView: BadgeView?

    public weak var nameView: NameView?

    public weak var weightView: WeightView?
    public weak var entryView: EntryView?
    public weak var quantityView: QuantityView?

    private var units: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    private var badge: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .label.contrast
        label.backgroundColor = .systemRed
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    private var button: UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }

    private var stackView: UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }

    private var customView: UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    weak var delegate: ShoppingCardCellViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let leftStackView = self.stackView
        leftStackView.axis = .horizontal
        leftStackView.setContentHuggingPriority(.required, for: .horizontal)

        let rightStackView = self.stackView
        rightStackView.axis = .horizontal
        rightStackView.setContentHuggingPriority(.required, for: .horizontal)

        let imageWrapper = self.customView
        let imageBadge = self.badge

        let imageBackground = self.customView
        imageBackground.layer.cornerRadius = 4
        imageBackground.layer.masksToBounds = true
        imageBackground.backgroundColor = .systemBackground

        let productImage = UIImageView()
        productImage.translatesAutoresizingMaskIntoConstraints = false
        productImage.contentMode = .scaleAspectFit
        productImage.layer.cornerRadius = 3
        productImage.layer.masksToBounds = true
        productImage.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        productImage.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        if #available(iOS 13.0, *) {
            spinner.style = .medium
        } else {
            spinner.style = .gray
        }

        let badgeView = BadgeView(frame: .zero)

        let nameView = NameView(frame: .zero)
        nameView.translatesAutoresizingMaskIntoConstraints = false
        nameView.setContentHuggingPriority(.defaultLow - 249, for: .horizontal)

        let weightView = WeightView(frame: .zero)
        let entryView = EntryView(frame: .zero)
        let quantityView = QuantityView(frame: .zero)

        rightStackView.addArrangedSubview(weightView)
        rightStackView.addArrangedSubview(entryView)
        rightStackView.addArrangedSubview(quantityView)

        quantityView.plusButton?.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)
        quantityView.minusButton?.addTarget(self, action: #selector(minusButtonTapped(_:)), for: .touchUpInside)

        addSubview(leftStackView)
        addSubview(nameView)
        addSubview(rightStackView)

        leftStackView.addArrangedSubview(badgeView)
        leftStackView.addArrangedSubview(imageWrapper)

        imageWrapper.addSubview(imageBackground)
        imageWrapper.addSubview(imageBadge)
        imageBackground.addSubview(productImage)
        productImage.addSubview(spinner)

        self.leftStackView = leftStackView
        self.nameView = nameView
        self.rightStackView = rightStackView

        self.badgeView = badgeView

        self.imageWrapper = imageWrapper
        self.imageBackground = imageBackground
        self.imageBadge = imageBadge
        self.productImage = productImage
        self.spinner = spinner

        self.weightView = weightView
        self.entryView = entryView
        self.quantityView = quantityView

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            leftStackView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: leftStackView.bottomAnchor),

            nameView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: nameView.bottomAnchor, constant: 8),
//            nameView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            rightStackView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: rightStackView.bottomAnchor),

            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            nameView.leadingAnchor.constraint(equalTo: leftStackView.trailingAnchor),
            rightStackView.leadingAnchor.constraint(equalTo: nameView.trailingAnchor),
            trailingAnchor.constraint(equalTo: rightStackView.trailingAnchor, constant: 12),

            // Subviews

//            badgeLabel.leadingAnchor.constraint(equalTo: leftStackView.leadingAnchor),
//            badgeLabel.topAnchor.constraint(equalTo: badgeWrapper.topAnchor, constant: 11),
//            badgeLabel.trailingAnchor.constraint(equalTo: badgeWrapper.trailingAnchor),

            imageBackground.leadingAnchor.constraint(equalTo: imageWrapper.leadingAnchor, constant: 8),
            imageBackground.widthAnchor.constraint(equalToConstant: 32),
            imageBackground.trailingAnchor.constraint(equalTo: imageWrapper.trailingAnchor, constant: -8),
            imageBackground.topAnchor.constraint(equalTo: imageWrapper.topAnchor, constant: 9),
            imageBackground.heightAnchor.constraint(equalToConstant: 32),

            imageBadge.topAnchor.constraint(equalTo: imageBackground.topAnchor),
            imageBadge.heightAnchor.constraint(equalToConstant: 16),
            imageBadge.widthAnchor.constraint(equalToConstant: 18),
            imageBadge.trailingAnchor.constraint(equalTo: imageBackground.leadingAnchor, constant: 8),

            productImage.widthAnchor.constraint(equalToConstant: 28),
            productImage.heightAnchor.constraint(equalToConstant: 28),
            productImage.centerYAnchor.constraint(equalTo: imageBackground.centerYAnchor),
            productImage.centerXAnchor.constraint(equalTo: imageBackground.centerXAnchor),

            spinner.topAnchor.constraint(equalTo: productImage.topAnchor),
            spinner.bottomAnchor.constraint(equalTo: productImage.bottomAnchor),
            spinner.leadingAnchor.constraint(equalTo: productImage.leadingAnchor),
            spinner.trailingAnchor.constraint(equalTo: productImage.trailingAnchor)
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

        imageBadge?.text = text
        imageBadge?.isHidden = text == nil
    }

    public func updateBadgeColor(withColor color: UIColor?) {
        if let color = color {
            badgeView?.backgroundView?.backgroundColor = color
            imageBadge?.backgroundColor = color
        }
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
        [imageWrapper, badgeView].forEach { $0?.isHidden = true }
        switch mode {
        case .none, .badge:
            badgeView?.isHidden = false
        case .image:
            imageWrapper?.isHidden = false
            imageBackground?.isHidden = false
        case .emptyImage:
            imageWrapper?.isHidden = false
            imageBackground?.isHidden = true
        }
    }

    public func updateRightDisplay(withMode mode: RightDisplay) {
        UIView.performWithoutAnimation { [self] in
            [quantityView, weightView, entryView].forEach { $0?.isHidden = true }
            switch mode {
            case .none: ()
            case .buttons:
                quantityView?.isHidden = false
            case .weightDisplay:
                weightView?.isHidden = false
            case .weightEntry:
                entryView?.isHidden = false
            }
        }
    }
}
