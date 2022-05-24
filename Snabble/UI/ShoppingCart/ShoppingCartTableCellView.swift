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
    private weak var leftStackView: UIStackView?
    private weak var centerStackView: UIStackView?
    private weak var rightStackView: UIStackView?

    public weak var badgeWrapper: UIView?
    public weak var badgeLabel: UILabel?

    public weak var imageWrapper: UIView?
    public weak var imageBadge: UILabel?
    public weak var imageBackground: UIView?
    public weak var productImage: UIImageView?
    public weak var spinner: UIActivityIndicatorView?

    public weak var nameLabel: UILabel?
    public weak var priceLabel: UILabel?

    public weak var weightWrapper: UIView?
    public weak var weightLabel: UILabel?
    public weak var weightUnits: UILabel?

    public weak var entryWrapper: UIView?
    public weak var quantityInput: UITextField?
    public weak var unitsLabel: UILabel!

    public weak var buttonWrapper: UIView?
    public weak var minusButton: UIButton?
    public weak var plusButton: UIButton?
    public weak var quantityLabel: UILabel?

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
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let leftStackView = self.stackView
        leftStackView.axis = .horizontal
        leftStackView.setContentHuggingPriority(.defaultLow + 2, for: .horizontal)

        let badgeWrapper = self.customView
        let badgeLabel = self.badge
        badgeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
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

        let centerStackView = self.stackView
        centerStackView.axis = .vertical

        let nameLabel = self.customLabel
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .natural
        nameLabel.numberOfLines = 0
        nameLabel.setContentHuggingPriority(.defaultLow + 2, for: .vertical)

        let priceLabel = self.customLabel
        priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        priceLabel.textColor = .systemGray
        priceLabel.textAlignment = .natural

        let rightStackView = self.stackView
        rightStackView.axis = .horizontal
        rightStackView.setContentHuggingPriority(.defaultLow + 2, for: .horizontal)

        let weightWrapper = self.customView
        let weightLabel = self.customLabel
        weightLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        weightLabel.textColor = .label
        weightLabel.textAlignment = .right

        let weightUnits = self.units
        let entryWrapper = self.customView
        let quantityInput = UITextField()
        quantityInput.translatesAutoresizingMaskIntoConstraints = false
        quantityInput.textColor = .label
        quantityInput.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityInput.textAlignment = .right
        quantityInput.borderStyle = .roundedRect
        quantityInput.backgroundColor = .secondarySystemBackground
        quantityInput.keyboardType = .numberPad
        quantityInput.minimumFontSize = 17
        quantityInput.adjustsFontSizeToFitWidth = true

        let unitsLabel = self.units
        let buttonWrapper = self.customView

        let minusButton = self.button
        minusButton.makeBorderedButton()
        minusButton.backgroundColor = .systemBackground
        minusButton.setImage(Asset.SnabbleSDK.iconMinus.image, for: .normal)
        minusButton.addTarget(self, action: #selector(minusButtonTapped(_:)), for: .touchUpInside)

        let quantityLabel = self.customLabel
        quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .center

        let plusButton = self.button
        plusButton.makeBorderedButton()
        plusButton.backgroundColor = .systemBackground
        plusButton.setImage(Asset.SnabbleSDK.iconPlus.image, for: .normal)
        plusButton.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)

        addSubview(leftStackView)
        addSubview(centerStackView)
        addSubview(rightStackView)

        leftStackView.addArrangedSubview(badgeWrapper)
        leftStackView.addArrangedSubview(imageWrapper)

        centerStackView.addArrangedSubview(nameLabel)
        centerStackView.addArrangedSubview(priceLabel)

        rightStackView.addArrangedSubview(weightWrapper)
        rightStackView.addArrangedSubview(entryWrapper)
        rightStackView.addArrangedSubview(buttonWrapper)

        badgeWrapper.addSubview(badgeLabel)

        imageWrapper.addSubview(imageBackground)
        imageWrapper.addSubview(imageBadge)
        imageBackground.addSubview(productImage)
        productImage.addSubview(spinner)

        weightWrapper.addSubview(weightLabel)
        weightWrapper.addSubview(weightUnits)

        entryWrapper.addSubview(quantityInput)
        entryWrapper.addSubview(unitsLabel)

        buttonWrapper.addSubview(minusButton)
        buttonWrapper.addSubview(quantityLabel)
        buttonWrapper.addSubview(plusButton)

        self.leftStackView = leftStackView
        self.badgeWrapper = badgeWrapper
        self.badgeLabel = badgeLabel
        self.imageWrapper = imageWrapper
        self.imageBackground = imageBackground
        self.imageBadge = imageBadge
        self.productImage = productImage
        self.spinner = spinner
        self.centerStackView = centerStackView
        self.nameLabel = nameLabel
        self.priceLabel = priceLabel
        self.rightStackView = rightStackView
        self.weightWrapper = weightWrapper
        self.weightLabel = weightLabel
        self.weightUnits = weightUnits
        self.entryWrapper = entryWrapper
        self.quantityInput = quantityInput
        self.unitsLabel = unitsLabel
        self.buttonWrapper = buttonWrapper
        self.minusButton = minusButton
        self.quantityLabel = quantityLabel
        self.plusButton = plusButton

        NSLayoutConstraint.activate([
            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            leftStackView.topAnchor.constraint(equalTo: topAnchor),
            leftStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftStackView.trailingAnchor.constraint(equalTo: centerStackView.leadingAnchor),

            badgeLabel.leadingAnchor.constraint(equalTo: leftStackView.leadingAnchor),
            badgeLabel.topAnchor.constraint(equalTo: badgeWrapper.topAnchor, constant: 11),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeWrapper.trailingAnchor, constant: -8),

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
            spinner.trailingAnchor.constraint(equalTo: productImage.trailingAnchor),

            centerStackView.trailingAnchor.constraint(equalTo: rightStackView.leadingAnchor),
            centerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: centerStackView.bottomAnchor, constant: 8).usingPriority(.required),
            centerStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            trailingAnchor.constraint(equalTo: rightStackView.trailingAnchor, constant: 12),
            rightStackView.topAnchor.constraint(equalTo: topAnchor),
            rightStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            weightLabel.leadingAnchor.constraint(equalTo: weightWrapper.leadingAnchor),
            weightLabel.widthAnchor.constraint(equalToConstant: 29),
            weightLabel.topAnchor.constraint(equalTo: weightWrapper.topAnchor, constant: 16),
            weightUnits.leadingAnchor.constraint(equalTo: weightLabel.trailingAnchor),
            weightUnits.widthAnchor.constraint(equalToConstant: 17),
            weightUnits.trailingAnchor.constraint(equalTo: weightWrapper.trailingAnchor),
            weightUnits.centerYAnchor.constraint(equalTo: weightLabel.centerYAnchor),

            quantityInput.leadingAnchor.constraint(equalTo: entryWrapper.leadingAnchor),
            quantityInput.widthAnchor.constraint(equalToConstant: 81),
            quantityInput.topAnchor.constraint(equalTo: entryWrapper.topAnchor, constant: 8),
            quantityInput.heightAnchor.constraint(equalToConstant: 32),
            unitsLabel.leadingAnchor.constraint(equalTo: quantityInput.trailingAnchor),
            unitsLabel.widthAnchor.constraint(equalToConstant: 17),
            unitsLabel.trailingAnchor.constraint(equalTo: entryWrapper.trailingAnchor),
            unitsLabel.centerYAnchor.constraint(equalTo: quantityInput.centerYAnchor),

            minusButton.leadingAnchor.constraint(equalTo: buttonWrapper.leadingAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 32),
            minusButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor, constant: 8),
            minusButton.heightAnchor.constraint(equalToConstant: 32),

            quantityLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor),
            quantityLabel.widthAnchor.constraint(equalToConstant: 34),
            quantityLabel.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 32),
            plusButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor),
            plusButton.heightAnchor.constraint(equalToConstant: 32),
            plusButton.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor)
        ])
    }

    @objc private func plusButtonTapped(_ sender: Any) {
        delegate?.plusButtonTapped()
    }

    @objc private func minusButtonTapped(_ sender: Any) {
        delegate?.minusButtonTapped()
    }

    public func updateBadgeText(withText text: String?) {
        self.badgeLabel?.text = text
        self.badgeLabel?.isHidden = text == nil
        self.imageBadge?.text = text
        self.imageBadge?.isHidden = text == nil
    }

    public func updateBadgeColor(withColor color: UIColor?) {
        if let color = color {
            self.badgeLabel?.backgroundColor = color
            self.imageBadge?.backgroundColor = color
        }
    }

    public func updateQuantityText(withText text: String?) {
        self.quantityLabel?.text = text
        self.weightLabel?.text = text
        self.quantityInput?.text = text
    }

    public func updateUnitsText(withText text: String?) {
        self.unitsLabel?.text = text
        self.weightUnits?.text = text
    }

    public func updateLeftDisplay(withMode mode: LeftDisplay) {
        [self.imageWrapper, self.badgeWrapper].forEach { $0?.isHidden = true }
        switch mode {
        case .none:
            self.badgeWrapper?.isHidden = false
            self.badgeLabel?.isHidden = true
        case .image:
            self.imageWrapper?.isHidden = false
            self.imageBackground?.isHidden = false
        case .emptyImage:
            self.imageWrapper?.isHidden = false
            self.imageBackground?.isHidden = true
        case .badge:
            self.badgeWrapper?.isHidden = false
        }
    }

    public func updateRightDisplay(withMode mode: RightDisplay) {
        UIView.performWithoutAnimation {
            [self.buttonWrapper, self.weightWrapper, self.entryWrapper].forEach { $0?.isHidden = true }
            switch mode {
            case .none: ()
            case .buttons: self.buttonWrapper?.isHidden = false
            case .weightDisplay: self.weightWrapper?.isHidden = false
            case .weightEntry: self.entryWrapper?.isHidden = false
            }
        }
    }
}
