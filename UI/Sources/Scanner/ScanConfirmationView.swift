//
//  ScanConfirmationView.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import WCAG_Colors
import SnabbleCore
import SnabbleAssetProviding

protocol ScanConfirmationViewDelegate: AnalyticsDelegate {
    func closeConfirmation(forItem item: CartItem?)
    func showMessage(_ message: ScanMessage)
    func showMessages(_ messages: [ScanMessage])
}

final class ScanConfirmationView: UIView {
    private weak var closeButton: UIButton?
    private weak var cartButton: UIButton?

    private weak var productStack: UIStackView?
    private weak var subtitleLabel: UILabel?
    private weak var productNameLabel: UILabel?
    private weak var originalPriceLabel: UILabel?
    private weak var priceLabel: UILabel?
    private var manualDiscountButton: UIButton?

    private weak var quantityStack: UIStackView?
    private weak var quantityField: UITextField?
    private weak var minusButton: UIButton?
    private weak var plusButton: UIButton?
    private weak var unitLabel: UILabel?

    private var shoppingCart: ShoppingCart!
    private var cartItem: CartItem!

    weak var delegate: ScanConfirmationViewDelegate?

    override var isFirstResponder: Bool {
        guard let textField = self.quantityField else { return false }
        return textField.isFirstResponder
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
    }

    var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .label
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    var squareButton: UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.makeBorderedButton()
        return button
    }

    private func setupUI() {
        self.addCornersAndShadow(backgroundColor: .systemBackground, cornerRadius: 8)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.isUserInteractionEnabled = true
        closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)

        let cartButton = UIButton(type: .system)
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.setTitle(Asset.localizedString(forKey: "Snabble.Scanner.addToCart"), for: .normal)
        cartButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        cartButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cartButton.makeSnabbleButton()
        cartButton.isUserInteractionEnabled = true
        cartButton.addTarget(self, action: #selector(cartButtonTapped(_:)), for: .touchUpInside)

        let productStack = UIStackView()
        productStack.translatesAutoresizingMaskIntoConstraints = false
        productStack.axis = .vertical
        productStack.distribution = .fill
        productStack.alignment = .center
        productStack.spacing = 4

        let subtitleLabel = customLabel
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.adjustsFontForContentSizeCategory = true

        let productNameLabel = customLabel
        productNameLabel.font = .preferredFont(forTextStyle: .body, weight: .bold)
        productNameLabel.adjustsFontForContentSizeCategory = true

        let originalPriceLabel = customLabel
        originalPriceLabel.font = .preferredFont(forTextStyle: .body)
        originalPriceLabel.adjustsFontForContentSizeCategory = true
        originalPriceLabel.textColor = .secondaryLabel

        let priceLabel = customLabel
        priceLabel.font = .preferredFont(forTextStyle: .body)
        priceLabel.adjustsFontForContentSizeCategory = true

        let manualDiscountButton = UIButton(type: .system)
        manualDiscountButton.translatesAutoresizingMaskIntoConstraints = false
        manualDiscountButton.setTitle(Asset.localizedString(forKey: "Snabble.addDiscount"), for: .normal)
        manualDiscountButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        manualDiscountButton.titleLabel?.adjustsFontForContentSizeCategory = true

        let contrastRatio = UIColor.getContrastRatio(forTextColor: .projectPrimary(),
                                                     onBackgroundColor: .systemBackground)
        let conformanceLevel = ConformanceLevel(contrastRatio: contrastRatio ?? 1, fontSize: 17, isBoldFont: false)

        if conformanceLevel == .AA || conformanceLevel == .AAA {
            manualDiscountButton.tintColor = .projectPrimary()
        } else {
            manualDiscountButton.tintColor = .label
        }
        manualDiscountButton.isUserInteractionEnabled = true
        manualDiscountButton.addTarget(self, action: #selector(manualDiscountTapped(_:)), for: .touchUpInside)

        let quantityStack = UIStackView()
        quantityStack.translatesAutoresizingMaskIntoConstraints = false
        quantityStack.axis = .horizontal
        quantityStack.distribution = .fill
        quantityStack.alignment = .fill
        quantityStack.spacing = 8

        let minusButton = squareButton
        minusButton.setImage(UIImage(systemName: "trash"), for: .normal)
        minusButton.addTarget(self, action: #selector(minusButtonTapped(_:)), for: .touchUpInside)

        let plusButton = squareButton
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)

        let quantityField = UITextField()
        quantityField.translatesAutoresizingMaskIntoConstraints = false
        quantityField.font = .preferredFont(forTextStyle: .title3)
        quantityField.adjustsFontForContentSizeCategory = true
        quantityField.tintColor = .label
        quantityField.delegate = self
        quantityField.addDoneButton()
        quantityField.textAlignment = .center
        quantityField.borderStyle = .roundedRect
        quantityField.keyboardType = .numberPad

        let unitLabel = customLabel
        unitLabel.font = .preferredFont(forTextStyle: .body)
        unitLabel.adjustsFontForContentSizeCategory = true
        unitLabel.textAlignment = .natural

        addSubview(closeButton)
        addSubview(productStack)
        addSubview(quantityStack)
        addSubview(cartButton)

        productStack.addArrangedSubview(subtitleLabel)
        productStack.addArrangedSubview(productNameLabel)
        productStack.addArrangedSubview(originalPriceLabel)
        productStack.addArrangedSubview(priceLabel)
        productStack.addArrangedSubview(manualDiscountButton)

        quantityStack.addArrangedSubview(minusButton)
        quantityStack.addArrangedSubview(quantityField)
        quantityStack.addArrangedSubview(plusButton)
        quantityStack.addArrangedSubview(unitLabel)

        self.closeButton = closeButton
        self.productStack = productStack
        self.subtitleLabel = subtitleLabel
        self.productNameLabel = productNameLabel
        self.originalPriceLabel = originalPriceLabel
        self.priceLabel = priceLabel
        self.manualDiscountButton = manualDiscountButton
        self.quantityStack = quantityStack
        self.minusButton = minusButton
        self.plusButton = plusButton
        self.quantityField = quantityField
        self.unitLabel = unitLabel
        self.cartButton = cartButton

        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            productStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            productStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            productStack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 12),

            quantityStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16).usingPriority(999),
            quantityStack.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor, constant: -16).usingPriority(999),
            quantityStack.topAnchor.constraint(equalTo: productStack.bottomAnchor, constant: 16),
            quantityStack.bottomAnchor.constraint(equalTo: cartButton.topAnchor, constant: -16),

            quantityField.widthAnchor.constraint(equalToConstant: 96),
            quantityField.centerXAnchor.constraint(equalTo: centerXAnchor),
            quantityField.heightAnchor.constraint(equalToConstant: 48),

            cartButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cartButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cartButton.heightAnchor.constraint(equalToConstant: 48),
            cartButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    func present(withProduct scannedProduct: ScannedProduct, withCode scannedCode: String, forCart cart: ShoppingCart) {
        // avoid ugly animations
        UIView.performWithoutAnimation {
            self.doPresent(withProduct: scannedProduct, withCode: scannedCode, forCart: cart)
            self.layoutIfNeeded()
        }
    }

    private func doPresent(withProduct scannedProduct: ScannedProduct, withCode scannedCode: String, forCart cart: ShoppingCart) {
        self.shoppingCart = cart

        let project = SnabbleCI.project
        self.manualDiscountButton?.isHidden = project.manualCoupons.isEmpty
        self.manualDiscountButton?.setTitle(Asset.localizedString(forKey: "Snabble.addDiscount"), for: .normal)

        let product = scannedProduct.product
        self.productNameLabel?.text = product.name

        var embeddedData = scannedProduct.embeddedData

        let scannedCode = ScannedCode(
            scannedCode: scannedCode,
            transmissionCode: scannedProduct.transmissionCode,
            embeddedData: embeddedData,
            encodingUnit: scannedProduct.encodingUnit,
            priceOverride: scannedProduct.priceOverride,
            referencePriceOverride: scannedProduct.referencePriceOverride,
            templateId: scannedProduct.templateId ?? CodeTemplate.defaultName,
            transmissionTemplateId: scannedProduct.transmissionTemplateId,
            lookupCode: scannedProduct.lookupCode)

        self.cartItem = CartItem(1, product, scannedCode, cart.customerCard, project.roundingMode)

        let cartQuantity = self.cartItem.canMerge ? self.shoppingCart.quantity(of: self.cartItem) : 0
        let alreadyInCart = cartQuantity > 0

        let initialQuantity = scannedProduct.specifiedQuantity ?? 1
        var quantity = cartQuantity + initialQuantity
        if product.type == .userMustWeigh {
            quantity = 0
        }

        if let embed = cartItem.scannedCode.embeddedData, product.referenceUnit?.hasDimension == true {
            quantity = embed
        }
        self.cartItem.setQuantity(quantity)

        self.priceLabel?.isHidden = false

        self.minusButton?.isHidden = !self.cartItem.editable
        self.plusButton?.isHidden = !self.cartItem.editable

        self.unitLabel?.text = cartItem.encodingUnit?.display
        self.unitLabel?.isHidden = !self.cartItem.editable

        self.quantityField?.isHidden = !self.cartItem.editable

        self.subtitleLabel?.text = product.subtitle

        if product.type == .userMustWeigh {
            self.quantityField?.becomeFirstResponder()
            self.plusButton?.isHidden = true
            self.minusButton?.isHidden = true
        }

        self.showQuantity(updateTextField: true)

        let cartTitle = alreadyInCart ? Asset.localizedString(forKey: "Snabble.Scanner.updateCart") : Asset.localizedString(forKey: "Snabble.Scanner.addToCart")
        self.cartButton?.setTitle(cartTitle, for: .normal)

        if product.discountedPrice != nil && product.discountedPrice != product.listPrice {
            let formatter = PriceFormatter(project)
            let originalPrice = formatter.format(product.listPrice)
            let str = NSAttributedString(string: originalPrice,
                                         attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
            self.originalPriceLabel?.attributedText = str
        } else {
            self.originalPriceLabel?.text = nil
        }

        // suppress display when price == 0
        var hasPrice = product.price(cart.customerCard) != 0
        if self.cartItem.encodingUnit == .price {
            hasPrice = true
        }
        if !hasPrice {
            self.priceLabel?.isHidden = true
            self.plusButton?.isHidden = true
            self.minusButton?.isHidden = true
            self.quantityField?.isEnabled = false
        }
    }

    private func showQuantity(updateTextField: Bool) {
        var quantity = self.cartItem.effectiveQuantity
        let product = self.cartItem.product

        self.cartButton?.isEnabled = quantity > 0

        if quantity < 1 && product.type != .userMustWeigh {
            quantity = 1
        } else if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }

        if updateTextField {
            self.quantityField?.text = quantity == 0 ? "" : "\(quantity)"
        }

        self.minusButton?.isEnabled = quantity > 1
        self.minusButton?.setImage(UIImage(systemName: quantity > 1 ? "minus" : "trash"), for: .normal)
        
        self.plusButton?.isEnabled = quantity < ShoppingCart.maxAmount

        self.quantityField?.isEnabled = self.cartItem.editable

        let formatter = PriceFormatter(SnabbleCI.project)
        let formattedPrice = self.cartItem.priceDisplay(formatter)
        let quantityDisplay = self.cartItem.quantityDisplay()

        let showQuantity = quantity != 1 || self.cartItem.product.deposit != nil
        self.priceLabel?.text = (showQuantity ? quantityDisplay + " " : "") + formattedPrice
    }

    @objc private func closeButtonTapped(_ sender: Any) {
        self.delegate?.track(.scanAborted(self.cartItem.product.sku))

        self.productNameLabel?.text = nil
        self.delegate?.closeConfirmation(forItem: nil)
        self.quantityField?.resignFirstResponder()

        NotificationCenter.default.post(name: .snabbleHideScanConfirmation, object: nil)
    }

    @objc private func cartButtonTapped(_ sender: Any) {
        let cart = self.shoppingCart!

        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.success)

        let cartQuantity = cart.quantity(of: self.cartItem)
        if cartQuantity == 0 || !self.cartItem.canMerge {
            let item = self.cartItem!
            Log.info("adding to cart: \(item.quantity) x \(item.product.name), scannedCode = \(item.scannedCode.code), embed=\(String(describing: item.scannedCode.embeddedData))")
            cart.add(self.cartItem)
        } else {
            Log.info("updating cart: set qty=\(self.cartItem.quantity) for \(self.cartItem.product.name)")
            cart.setQuantity(self.cartItem.quantity, for: self.cartItem)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.delegate?.track(.productAddedToCart(self.cartItem.product.sku))
        if let shop = Snabble.shared.checkInManager.shop,
           let project = shop.project,
           let location = Snabble.shared.checkInManager.locationManager.location {
            AppEvent(key: "Add to cart distance to shop", value: "\(shop.id.rawValue);\(shop.distance(to: location))m", project: project, shopId: shop.id).post()
        }

        self.productNameLabel?.text = nil
        self.delegate?.closeConfirmation(forItem: self.cartItem)

        self.quantityField?.resignFirstResponder()

        let userInfo: [String: Any] = [
            "scannedCode": self.cartItem.scannedCode.code,
            "sku": self.cartItem.product.sku,
            "name": self.cartItem.product.name
        ]
        NotificationCenter.default.post(name: .snabbleHideScanConfirmation, object: nil, userInfo: userInfo)
    }

    @objc private func manualDiscountTapped(_ sender: Any) {
        let project = SnabbleCI.project

        let title = Asset.localizedString(forKey: "Snabble.addDiscount")
        let actionSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.noDiscount"), style: .default) { _ in
            self.cartItem.setManualCoupon(nil)
            self.showQuantity(updateTextField: true)
            self.manualDiscountButton?.setTitle(title, for: .normal)
        })

        for coupon in project.manualCoupons {
            actionSheet.addAction(UIAlertAction(title: coupon.name, style: .default) { _ in
                let cartQuantity = self.shoppingCart.quantity(of: self.cartItem)
                if cartQuantity > 0 {
                    self.cartItem.setQuantity(1)
                }
                self.cartItem.setManualCoupon(coupon)
                self.showQuantity(updateTextField: true)
                self.manualDiscountButton?.setTitle(coupon.name, for: .normal)
                self.cartButton?.setTitle(Asset.localizedString(forKey: "Snabble.Scanner.addToCart"), for: .normal)
            })
        }

        actionSheet.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .cancel, handler: nil))

        UIApplication.topViewController()?.present(actionSheet, animated: true)
    }

    @objc private func minusButtonTapped(_ sender: Any) {
        self.cartItem.setQuantity(self.cartItem.quantity - 1)
        self.showQuantity(updateTextField: true)
    }

    @objc private func plusButtonTapped(_ sender: Any) {
        self.cartItem.setQuantity(self.cartItem.quantity + 1)
        self.showQuantity(updateTextField: true)
    }

}

extension ScanConfirmationView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else {
            return false
        }

        let newText = text.replacingCharacters(in: range, with: string)
        let qty = Int(newText) ?? 0

        if qty < 0 || qty > ShoppingCart.maxAmount || (range.location == 0 && string == "0") {
            return false
        }

        self.cartItem.setQuantity(qty)
        self.showQuantity(updateTextField: false)

        return true
    }
}
