//
//  ShoppingCartTableCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

protocol ShoppingCartTableDelegate: AnalyticsDelegate {
    func confirmDeletion(at row: Int)
    func updateQuantity(_ quantity: Int, at row: Int)
    func makeRowVisible(row: Int)
    var showImages: Bool { get }
}

private enum LeftDisplay {
    case none
    case image
    case emptyImage
    case badge
}

private enum RightDisplay {
    case none
    case buttons
    case weightEntry
    case weightDisplay
}

final class ShoppingCartTableCell: UITableViewCell {
    @IBOutlet private var imageWrapper: UIView!
    @IBOutlet private var imageBadge: UILabel!
    @IBOutlet private var productImage: UIImageView!
    @IBOutlet private var imageBackground: UIView!
    @IBOutlet private var spinner: UIActivityIndicatorView!

    @IBOutlet private var badgeWrapper: UIView!
    @IBOutlet private var badgeLabel: UILabel!

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!

    @IBOutlet private var buttonWrapper: UIView!
    @IBOutlet private var minusButton: UIButton!
    @IBOutlet private var plusButton: UIButton!
    @IBOutlet private var quantityLabel: UILabel!

    @IBOutlet private var entryWrapper: UIView!
    @IBOutlet private var quantityInput: UITextField!
    @IBOutlet private var unitsLabel: UILabel!

    @IBOutlet private var weightWrapper: UIView!
    @IBOutlet private var weightLabel: UILabel!
    @IBOutlet private var weightUnits: UILabel!

    private var quantity = 0
    private var item: CartItem?
    private var lineItems = [CheckoutInfo.LineItem]()

    private weak var delegate: ShoppingCartTableDelegate?
    private var task: URLSessionDataTask?
    private var doneButton: UIBarButtonItem?

    // convenience setters for stuff we display in multiple places
    private var badgeText: String? {
        didSet {
            self.badgeLabel.text = badgeText
            self.badgeLabel.isHidden = badgeText == nil
            self.imageBadge.text = badgeText
            self.imageBadge.isHidden = badgeText == nil
        }
    }

    private var badgeColor: UIColor? {
        didSet {
            if let color = badgeColor {
                self.badgeLabel.backgroundColor = color
                self.imageBadge.backgroundColor = color
            }
        }
    }

    private var quantityText: String? {
        didSet {
            self.quantityLabel.text = quantityText
            self.weightLabel.text = quantityText
            self.quantityInput.text = quantityText
        }
    }

    private var unitsText: String? {
        didSet {
            self.unitsLabel.text = unitsText
            self.weightUnits.text = unitsText
        }
    }

    private var leftDisplay: LeftDisplay = .none {
        didSet {
            UIView.performWithoutAnimation {
                [imageWrapper, badgeWrapper].forEach { $0?.isHidden = true }
                switch leftDisplay {
                case .none: ()
                case .image:
                    imageWrapper.isHidden = false
                    imageBackground.isHidden = false
                case .emptyImage:
                    imageWrapper.isHidden = false
                    imageBackground.isHidden = true
                case .badge:
                    badgeWrapper.isHidden = false
                }
            }
        }
    }

    private var rightDisplay: RightDisplay = .buttons {
        didSet {
            UIView.performWithoutAnimation {
                [buttonWrapper, weightWrapper, entryWrapper].forEach { $0?.isHidden = true }
                switch rightDisplay {
                case .none: ()
                case .buttons: buttonWrapper.isHidden = false
                case .weightDisplay: weightWrapper.isHidden = false
                case .weightEntry: entryWrapper.isHidden = false
                }
            }
        }
    }

    private var showImages: Bool {
        self.delegate?.showImages == true
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.minusButton.makeBorderedButton()
        self.minusButton.backgroundColor = .systemBackground
        self.plusButton.makeBorderedButton()
        self.plusButton.backgroundColor = .systemBackground

        self.priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let toolbar = self.quantityInput.addDoneButton()
        self.doneButton = toolbar.items?.last
        self.quantityInput.delegate = self

        for badge in [self.badgeLabel, self.imageBadge] {
            badge?.layer.cornerRadius = 4
            badge?.layer.masksToBounds = true
        }

        self.imageBackground.layer.cornerRadius = 4
        self.imageBackground.layer.masksToBounds = true

        self.productImage.layer.cornerRadius = 3
        self.productImage.layer.masksToBounds = true

        self.selectionStyle = .none
        self.prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.task?.cancel()
        self.task = nil
        self.item = nil
        self.lineItems = []
        self.quantity = 0

        self.productImage.image = nil

        self.leftDisplay = .none
        self.rightDisplay = .none

        self.nameLabel.text = nil
        self.priceLabel.text = nil
        self.priceLabel.isHidden = false
        self.quantityText = nil
        self.unitsText = nil
        self.badgeText = nil
        self.badgeColor = .systemRed
    }

    func setLineItem(_ mainItem: CheckoutInfo.LineItem, _ lineItems: [CheckoutInfo.LineItem], row: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate

        self.nameLabel.text = mainItem.name

        self.loadImage()
        self.displayLineItemPrice(nil, mainItem, lineItems)

        self.quantityText = "\(mainItem.amount)"
    }

    func setDiscount(_ amount: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate

        self.nameLabel.text = L10n.Snabble.Shoppingcart.discounts

        let formatter = PriceFormatter(SnabbleUI.project)
        self.priceLabel.text = formatter.format(amount)

        if showImages {
            let icon = Asset.SnabbleSDK.iconPercent.image
            self.productImage.image = icon.recolored(with: .label)
            self.leftDisplay = .image
        }
    }

    func setGiveaway(_ lineItem: CheckoutInfo.LineItem, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate

        self.nameLabel.text = lineItem.name

        self.priceLabel.text = L10n.Snabble.Shoppingcart.giveaway

        if showImages {
            let icon = Asset.SnabbleSDK.iconGiveaway.image
            self.productImage.image = icon.recolored(with: SnabbleUI.appearance.accentColor)
            self.leftDisplay = .image
        }
    }

    func setCartItem(_ item: CartItem, _ lineItems: [CheckoutInfo.LineItem], row: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate
        self.item = item
        self.lineItems = lineItems

        let defaultItem = lineItems.first { $0.type == .default }

        self.quantity = defaultItem?.weight ?? defaultItem?.amount ?? item.quantity

        let product = item.product
        self.nameLabel.text = defaultItem?.name ?? product.name

        self.minusButton.tag = row
        self.plusButton.tag = row
        self.quantityInput.tag = row

        if item.editable {
            self.rightDisplay = .buttons
        } else if product.type == .userMustWeigh {
            self.rightDisplay = .weightEntry
        } else if product.type == .preWeighed {
            self.rightDisplay = .weightDisplay
        }
        self.quantityText = "\(item.quantity)"

        self.loadImage()
        self.showQuantity()

        // suppress display when price == 0
        let price = defaultItem?.totalPrice ?? item.price
        if price == 0 {
            self.priceLabel.text = ""
            self.priceLabel.isHidden = true
            self.rightDisplay = .none
        }
    }

    func setCouponItem(_ coupon: CartCoupon, _ lineItem: CheckoutInfo.LineItem?, row: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate
        self.quantity = 1
        self.nameLabel.text = coupon.coupon.name
        self.rightDisplay = .none

        self.quantityText = "1"

        let redeemed = lineItem?.redeemed == true

        if showImages {
            let icon = Asset.SnabbleSDK.iconPercent.image
            self.productImage.image = icon.recolored(with: redeemed ? .label : .systemGray)
            self.leftDisplay = .image
        } else {
            self.leftDisplay = .badge
            self.badgeText = "%"
            self.badgeColor = redeemed ? .systemRed : .systemGray
        }
    }

    private func updateQuantity(at row: Int, reload: Bool = true) {
        guard let item = self.item else {
            return
        }

        if self.quantity == 0 && item.product.type != .userMustWeigh {
            self.delegate?.confirmDeletion(at: row)
            return
        }

        self.delegate?.track(.cartAmountChanged)

        self.item?.quantity = self.quantity
        if reload {
            self.delegate?.updateQuantity(self.quantity, at: row)
        }

        self.showQuantity()
    }

    private func showQuantity() {
        guard let item = self.item else {
            return
        }

        let showWeight = item.product.referenceUnit?.hasDimension == true || item.product.type == .userMustWeigh
        let showQuantity = item.product.type == .singleItem || showWeight
        let encodingUnit = item.encodingUnit ?? item.product.encodingUnit
        let unit = encodingUnit?.display ?? ""
        let unitDisplay = showWeight ? " \(unit)" : nil

        self.quantityText = showQuantity ? "\(item.effectiveQuantity)" : nil
        self.unitsText = unitDisplay

        var badgeText: String?
        if item.manualCoupon != nil {
            badgeText = "%"
        }
        let saleRestricton = item.product.saleRestriction
        switch saleRestricton {
        case .none: ()
        case .age(let age): badgeText = "\(age)"
        case .fsk: badgeText = "FSK"
        }
        self.badgeText = badgeText
        if badgeText != nil {
            self.leftDisplay = showImages ? .image : .badge
        }

        if let defaultItem = lineItems.first(where: { $0.type == .default }) {
            let units = defaultItem.units ?? 1
            let amount = defaultItem.weight ?? (defaultItem.amount * units)
            self.quantityText = showQuantity ? "\(amount)" : nil
            self.unitsText = unitDisplay
            self.displayLineItemPrice(item.product, defaultItem, lineItems)
        } else {
            let formatter = PriceFormatter(SnabbleUI.project)
            self.priceLabel.text = formatter.format(item.price)
        }
    }

    private func displayLineItemPrice(_ product: Product?, _ mainItem: CheckoutInfo.LineItem, _ lineItems: [CheckoutInfo.LineItem]) {
        let formatter = PriceFormatter(SnabbleUI.project)

        var badgeColor: UIColor?
        var badgeText: String?
        if mainItem.priceModifiers != nil {
            badgeText = "%"
        }
        if let couponItem = lineItems.first(where: { $0.type == .coupon && $0.refersTo == mainItem.id }) {
            badgeText = "%"
            let redeemed = couponItem.redeemed == true
            badgeColor = redeemed ? .systemRed : .systemGray
        }

        if let saleRestricton = product?.saleRestriction {
            switch saleRestricton {
            case .none: ()
            case .age(let age):
                badgeText = "\(age)"
                badgeColor = .systemRed
            case .fsk:
                badgeText = "FSK"
                badgeColor = .systemRed
            }
        }
        self.badgeText = badgeText
        if let color = badgeColor {
            self.badgeColor = color
        }
        if badgeText != nil {
            self.leftDisplay = showImages ? .image : .badge
        }

        if let depositTotal = lineItems.first(where: { $0.type == .deposit })?.totalPrice {
            let total = formatter.format((mainItem.totalPrice ?? 0) + depositTotal)
            let includesDeposit = L10n.Snabble.Shoppingcart.includesDeposit
            self.priceLabel.text = "\(total) \(includesDeposit)"
        } else {
            let total = formatter.format(mainItem.totalPrice ?? 0)
            self.priceLabel.text = "\(total)"
        }
    }

    @IBAction private func minusButtonTapped(_ button: UIButton) {
        if self.quantity > 0 {
            self.quantity -= 1
            self.updateQuantity(at: button.tag)
        }
    }

    @IBAction private func plusButtonTapped(_ button: UIButton) {
        if self.quantity < ShoppingCart.maxAmount {
            self.quantity += 1
            self.updateQuantity(at: button.tag)
        }
    }

}

extension ShoppingCartTableCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else {
            return false
        }

        let newText = text.replacingCharacters(in: range, with: string).trimmingCharacters(in: .whitespacesAndNewlines)
        let qty = Int(newText) ?? 0

        self.doneButton?.isEnabled = qty > 0
        if qty > ShoppingCart.maxAmount || (range.location == 0 && string == "0") {
            return false
        }

        self.quantity = qty
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            self.updateQuantity(at: textField.tag)
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.delegate?.makeRowVisible(row: textField.tag)
        return true
    }

}

extension ShoppingCartTableCell: CustomizableAppearance {
    func setCustomAppearance(_ appearance: CustomAppearance) {
        // nop
    }
}

// MARK: - image loading

extension ShoppingCartTableCell {
    private static var imageCache = [String: UIImage]()

    private func loadImage() {
        guard
            let imgUrl = self.item?.product.imageUrl,
            let url = URL(string: imgUrl)
        else {
            if self.showImages {
                self.leftDisplay = .emptyImage
            }
            return
        }

        self.leftDisplay = .image

        if let img = ShoppingCartTableCell.imageCache[imgUrl] {
            self.productImage.image = img
            return
        }

        self.spinner.startAnimating()
        self.task = Snabble.urlSession.dataTask(with: url) { data, _, error in
            self.task = nil
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
            guard let data = data, error == nil else {
                return
            }

            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    ShoppingCartTableCell.imageCache[imgUrl] = image
                    self.productImage.image = image
                }
            }
        }
        self.task?.resume()
    }
}
