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

final class EntryView: UIView {
    private(set) weak var quantityLabel: UILabel?
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

        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .center
        quantityLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        super.init(frame: frame)

        addSubview(quantityTextField)
        addSubview(quantityLabel)

        self.quantityTextField = quantityTextField
        self.quantityLabel = quantityLabel

        NSLayoutConstraint.activate([
            quantityTextField.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
            bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: quantityTextField.bottomAnchor, multiplier: 1),
            quantityTextField.centerYAnchor.constraint(equalTo: centerYAnchor),

            quantityLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 1),
            bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: quantityLabel.bottomAnchor, multiplier: 1),
            quantityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            quantityTextField.widthAnchor.constraint(equalToConstant: 80).usingPriority(.defaultHigh),
            quantityTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            quantityTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            quantityLabel.leadingAnchor.constraint(equalTo: quantityTextField.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: quantityLabel.trailingAnchor)
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
        quantityLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
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
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let leftStackView = self.stackView
        leftStackView.axis = .horizontal
        leftStackView.setContentHuggingPriority(.required, for: .horizontal)

        let centerStackView = self.stackView
        centerStackView.axis = .vertical

        let rightStackView = self.stackView
        rightStackView.axis = .horizontal
        rightStackView.setContentHuggingPriority(.required, for: .horizontal)

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

        let nameLabel = self.customLabel
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .natural
        nameLabel.numberOfLines = 0

        let priceLabel = self.customLabel
        priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        priceLabel.textColor = .systemGray
        priceLabel.textAlignment = .natural

        let weightWrapper = self.customView
        let weightLabel = self.customLabel
        weightLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        weightLabel.textColor = .label
        weightLabel.textAlignment = .right

        let weightUnits = self.units

        let entryView = EntryView(frame: .zero)

        let quantityView = QuantityView(frame: .zero)
        quantityView.plusButton?.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)
        quantityView.minusButton?.addTarget(self, action: #selector(minusButtonTapped(_:)), for: .touchUpInside)

        addSubview(leftStackView)
        addSubview(centerStackView)
        addSubview(rightStackView)

        leftStackView.addArrangedSubview(badgeWrapper)
        leftStackView.addArrangedSubview(imageWrapper)

        centerStackView.addArrangedSubview(nameLabel)
        centerStackView.addArrangedSubview(priceLabel)

        rightStackView.addArrangedSubview(weightWrapper)
        rightStackView.addArrangedSubview(entryView)
        rightStackView.addArrangedSubview(quantityView)

        badgeWrapper.addSubview(badgeLabel)

        imageWrapper.addSubview(imageBackground)
        imageWrapper.addSubview(imageBadge)
        imageBackground.addSubview(productImage)
        productImage.addSubview(spinner)

        weightWrapper.addSubview(weightLabel)
        weightWrapper.addSubview(weightUnits)

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
        self.entryView = entryView
        self.quantityView = quantityView

        NSLayoutConstraint.activate([
            leftStackView.topAnchor.constraint(equalTo: topAnchor),
            leftStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            leftStackView.trailingAnchor.constraint(equalTo: centerStackView.leadingAnchor),

            badgeLabel.leadingAnchor.constraint(equalTo: leftStackView.leadingAnchor),
            badgeLabel.topAnchor.constraint(equalTo: badgeWrapper.topAnchor, constant: 11),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeWrapper.trailingAnchor),

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
            bottomAnchor.constraint(equalTo: centerStackView.bottomAnchor, constant: 8),
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
            weightUnits.centerYAnchor.constraint(equalTo: weightLabel.centerYAnchor)
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
        self.quantityView?.quantityLabel?.text = text
        self.weightLabel?.text = text
        self.entryView?.quantityTextField?.text = text
    }

    public func updateUnitsText(withText text: String?) {
        self.entryView?.quantityLabel?.text = text
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
        UIView.performWithoutAnimation { [self] in
            [quantityView, weightWrapper, entryView].forEach { $0?.isHidden = true }
            switch mode {
            case .none: ()
            case .buttons:
                quantityView?.isHidden = true
                weightWrapper?.isHidden = false
                entryView?.isHidden = false
            case .weightDisplay:
                weightWrapper?.isHidden = false
            case .weightEntry:
                entryView?.isHidden = false
            }
        }
    }
}
