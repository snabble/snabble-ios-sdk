//
//  ShoppingListCellView.swift
//  Snabble
//
//  Created by Anastasia Mishur on 7.04.22.
//

import Foundation

final class ShoppingListCellView: UIView {
    private weak var productImage: UIImageView?
    public weak var spinner: UIActivityIndicatorView?

    private weak var nameLabel: UILabel?

    private weak var quantityLabel: UILabel?
    private weak var checkContainer: UIView?
    private weak var checkImage: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let imageViewLayuotGuide = UILayoutGuide()

        let productImage = UIImageView()
        productImage.translatesAutoresizingMaskIntoConstraints = false
        productImage.contentMode = .scaleAspectFit
        productImage.tintColor = .label

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .preferredFont(forTextStyle: .subheadline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label
        nameLabel.textAlignment = .natural
        nameLabel.numberOfLines = 0

        let tickLayoutGuide = UILayoutGuide()

        let checkContainer = UIView()
        checkContainer.translatesAutoresizingMaskIntoConstraints = false
        checkContainer.backgroundColor = .systemTeal
        checkContainer.layer.shadowColor = UIColor.systemGray3.cgColor
        checkContainer.layer.shadowOpacity = 0.3
        checkContainer.layer.shadowOffset = CGSize.zero
        checkContainer.layer.shadowRadius = 1.5
        checkContainer.layer.masksToBounds = true
        checkContainer.layer.borderWidth = 1 / UIScreen.main.scale
        checkContainer.layer.borderColor = UIColor.systemBackground.cgColor
        checkContainer.layer.cornerRadius = 12
        checkContainer.backgroundColor = .clear

        let checkImage = UIImageView()
        checkImage.translatesAutoresizingMaskIntoConstraints = false
        checkImage.contentMode = .scaleAspectFit
        checkImage.image = Asset.image(named: "SnabbleSDK/icon-check-large")

        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.font = .preferredFont(forTextStyle: .footnote)
        quantityLabel.adjustsFontForContentSizeCategory = true
        quantityLabel.textColor = .label
        quantityLabel.textAlignment = .center
        quantityLabel.numberOfLines = 1

        addLayoutGuide(imageViewLayuotGuide)
        addLayoutGuide(tickLayoutGuide)

        addSubview(productImage)
        addSubview(spinner)
        addSubview(nameLabel)
        addSubview(quantityLabel)
        addSubview(checkContainer)
        checkContainer.addSubview(checkImage)

        self.productImage = productImage
        self.spinner = spinner
        self.nameLabel = nameLabel
        self.quantityLabel = quantityLabel
        self.checkContainer = checkContainer
        self.checkImage = checkImage

        NSLayoutConstraint.activate([
            imageViewLayuotGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageViewLayuotGuide.widthAnchor.constraint(equalToConstant: 42),
            imageViewLayuotGuide.topAnchor.constraint(equalTo: topAnchor),
            imageViewLayuotGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            productImage.leadingAnchor.constraint(equalTo: imageViewLayuotGuide.leadingAnchor, constant: 14),
            productImage.widthAnchor.constraint(equalToConstant: 28),
            productImage.heightAnchor.constraint(equalToConstant: 28),
            productImage.centerYAnchor.constraint(equalTo: imageViewLayuotGuide.centerYAnchor),

            spinner.topAnchor.constraint(equalTo: productImage.topAnchor),
            spinner.bottomAnchor.constraint(equalTo: productImage.bottomAnchor),
            spinner.leadingAnchor.constraint(equalTo: productImage.leadingAnchor),
            spinner.trailingAnchor.constraint(equalTo: productImage.trailingAnchor),

            tickLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            tickLayoutGuide.widthAnchor.constraint(equalToConstant: 46),
            tickLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            tickLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: imageViewLayuotGuide.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: tickLayoutGuide.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            checkContainer.trailingAnchor.constraint(equalTo: tickLayoutGuide.trailingAnchor).usingPriority(.defaultHigh),
            checkContainer.widthAnchor.constraint(equalToConstant: 24).usingPriority(.defaultHigh + 1),
            checkContainer.heightAnchor.constraint(equalToConstant: 24),
            checkContainer.centerYAnchor.constraint(equalTo: tickLayoutGuide.centerYAnchor),

            checkImage.leadingAnchor.constraint(equalTo: checkContainer.leadingAnchor, constant: 6),
            checkImage.trailingAnchor.constraint(equalTo: checkContainer.trailingAnchor, constant: -6),
            checkImage.topAnchor.constraint(equalTo: checkContainer.topAnchor, constant: 6),
            checkImage.bottomAnchor.constraint(equalTo: checkContainer.bottomAnchor, constant: -6),

            quantityLabel.leadingAnchor.constraint(equalTo: tickLayoutGuide.leadingAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: checkContainer.leadingAnchor),
            quantityLabel.heightAnchor.constraint(equalToConstant: 24),
            quantityLabel.centerYAnchor.constraint(equalTo: tickLayoutGuide.centerYAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }

    public func prepareForReuse() {
        self.productImage?.image = nil
        self.quantityLabel?.text = nil
        self.nameLabel?.text = nil
    }

    public func configure(withName attributedText: NSAttributedString, isItemChecked: Bool, quantity: String?) {
        self.quantityLabel?.text = quantity
        self.checkImage?.isHidden = !isItemChecked

        let alpha = isItemChecked ? 0.3 : 1
        self.nameLabel?.alpha = alpha
        self.checkContainer?.alpha = alpha
        self.quantityLabel?.alpha = alpha
        self.nameLabel?.attributedText = attributedText
    }

    public func configureProductImage(with image: UIImage?) {
        self.productImage?.image = image
    }
}
