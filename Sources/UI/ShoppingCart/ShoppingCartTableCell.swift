//
//  ShoppingCartTableCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

protocol ShoppingCartTableDelegate: AnalyticsDelegate {
    func confirmDeletion(at row: Int)
    func updateQuantity(_ quantity: Int, at row: Int)
    func makeRowVisible(row: Int)
    var showImages: Bool { get }
}

enum LeftDisplay {
    case none
    case image
    case emptyImage
    case badge
}

enum RightDisplay {
    case none
    case buttons
    case weightEntry
    case weightDisplay
}

final class ShoppingCartTableCell: UITableViewCell {

    private weak var cellView: ShoppingCartTableCellView?

    private var quantity = 0
    private var item: CartItem?
    private var lineItems = [CheckoutInfo.LineItem]()
    private var row: Int?

    private weak var delegate: ShoppingCartTableDelegate?
    private var task: URLSessionDataTask?
    private var doneButton: UIBarButtonItem?

    // convenience setters for stuff we display in multiple places
    private var badgeText: String? {
        didSet {
            self.cellView?.updateBadgeText(withText: badgeText)
        }
    }

    private var badgeColor: UIColor? {
        didSet {
            self.cellView?.updateBadgeColor(withColor: badgeColor)
        }
    }

    private var quantityText: String? {
        didSet {
            self.cellView?.updateQuantityText(withText: quantityText)
        }
    }

    private var unitsText: String? {
        didSet {
            self.cellView?.updateUnitsText(withText: unitsText)
        }
    }

    private var leftDisplay: LeftDisplay = .none {
        didSet {
            UIView.performWithoutAnimation {
                self.cellView?.updateLeftDisplay(withMode: leftDisplay)
            }
        }
    }

    private var rightDisplay: RightDisplay = .buttons {
        didSet {
            UIView.performWithoutAnimation {
                self.cellView?.updateRightDisplay(withMode: self.rightDisplay)
            }
        }
    }

    private var showImages: Bool {
        self.delegate?.showImages == true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let cellView = ShoppingCartTableCellView(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.addSubview(cellView)
        self.cellView = cellView
        self.cellView?.delegate = self
        self.cellView?.entryView?.quantityTextField?.delegate = self

        let toolbar = self.cellView?.entryView?.quantityTextField?.addDoneButton()
        self.doneButton = toolbar?.items?.last

        self.selectionStyle = .none

        prepareForReuse()

        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
            cellView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.task?.cancel()
        self.task = nil
        self.item = nil
        self.lineItems = []
        self.quantity = 0
        self.row = nil

        self.cellView?.imageView?.imageView?.image = nil

        self.leftDisplay = .none
        self.rightDisplay = .none

        self.cellView?.nameView?.nameLabel?.text = nil
        self.cellView?.nameView?.priceLabel?.text = nil
        self.cellView?.nameView?.priceLabel?.isHidden = false
        self.quantityText = nil
        self.unitsText = nil
        self.badgeText = nil
        self.badgeColor = .systemRed
    }

    func configureCell(row: Int, delegate: ShoppingCartTableDelegate) {
        self.row = row
        self.delegate = delegate
    }

    func setLineItem(_ mainItem: CheckoutInfo.LineItem, for lineItems: [CheckoutInfo.LineItem]) {
        self.cellView?.nameView?.nameLabel?.text = mainItem.name

        self.loadImage()
        self.displayLineItemPrice(for: nil, item: mainItem, in: lineItems)

        self.quantityText = "\(mainItem.amount)"
    }

    func setDiscount(for amount: Int) {
        self.cellView?.nameView?.nameLabel?.text = Asset.localizedString(forKey: "Snabble.Shoppingcart.discounts")

        let formatter = PriceFormatter(SnabbleCI.project)
        self.cellView?.nameView?.priceLabel?.text = formatter.format(amount)

        if showImages {
            let icon: UIImage? = Asset.image(named: "SnabbleSDK/icon-percent")
            self.cellView?.imageView?.imageView?.image = icon?.recolored(with: .label)
            self.leftDisplay = .image
        }
    }

    func setGiveaway(for lineItem: CheckoutInfo.LineItem) {
        self.cellView?.nameView?.nameLabel?.text = lineItem.name

        self.cellView?.nameView?.priceLabel?.text = Asset.localizedString(forKey: "Snabble.Shoppingcart.giveaway")

        if showImages {
            let icon: UIImage? = Asset.image(named: "SnabbleSDK/icon-giveaway")
            self.cellView?.imageView?.imageView?.image = icon?.recolored(with: .accent())
            self.leftDisplay = .image
        }
    }

    func setCartItem(_ item: CartItem, for lineItems: [CheckoutInfo.LineItem]) {
        self.item = item
        self.lineItems = lineItems

        let defaultItem = lineItems.first { $0.type == .default }

        self.quantity = defaultItem?.weight ?? defaultItem?.amount ?? item.quantity

        let product = item.product
        self.cellView?.nameView?.nameLabel?.text = defaultItem?.name ?? product.name

        if item.editable {
            if product.type == .userMustWeigh {
                self.rightDisplay = .weightEntry
            } else {
                self.rightDisplay = .buttons
            }
        } else if product.type == .preWeighed {
            self.rightDisplay = .weightDisplay
        }

        self.quantityText = "\(item.quantity)"

        self.loadImage()
        self.showQuantity()

        // suppress display when price == 0
        let price = defaultItem?.totalPrice ?? item.price
        if price == 0 {
            self.cellView?.nameView?.priceLabel?.text = ""
            self.cellView?.nameView?.priceLabel?.isHidden = true
            self.rightDisplay = .none
        }
    }

    func setCouponItem(_ coupon: CartCoupon, for lineItem: CheckoutInfo.LineItem?) {
        self.quantity = 1
        self.cellView?.nameView?.nameLabel?.text = coupon.coupon.name
        self.rightDisplay = .none

        self.quantityText = "1"

        let redeemed = lineItem?.redeemed == true

        if showImages {
            let icon: UIImage? = Asset.image(named: "SnabbleSDK/icon-percent")
            self.cellView?.imageView?.imageView?.image = icon?.recolored(with: redeemed ? .label : .systemGray)
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

        self.item?.setQuantity(self.quantity)
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
            self.displayLineItemPrice(for: item.product, item: defaultItem, in: lineItems)
        } else {
            let formatter = PriceFormatter(SnabbleCI.project)
            self.cellView?.nameView?.priceLabel?.text = formatter.format(item.price)
        }
    }

    private func displayLineItemPrice(for product: Product?, item: CheckoutInfo.LineItem, in lineItems: [CheckoutInfo.LineItem]) {
        let formatter = PriceFormatter(SnabbleCI.project)

        var badgeColor: UIColor?
        var badgeText: String?
        if item.priceModifiers != nil {
            badgeText = "%"
        }
        if let couponItem = lineItems.first(where: { $0.type == .coupon && $0.refersTo == item.id }) {
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
            let total = formatter.format((item.totalPrice ?? 0) + depositTotal)
            let includesDeposit = Asset.localizedString(forKey: "Snabble.Shoppingcart.includesDeposit")
            self.cellView?.nameView?.priceLabel?.text = "\(total) \(includesDeposit)"
        } else {
            let total = formatter.format(item.totalPrice ?? 0)
            self.cellView?.nameView?.priceLabel?.text = "\(total)"
        }
    }
}

extension ShoppingCartTableCell: ShoppingCardCellViewDelegate {
    func minusButtonTapped() {
        guard let row = self.row else { return }
        if self.quantity > 0 {
            self.quantity -= 1
            self.updateQuantity(at: row)
        }
    }

    func plusButtonTapped() {
        guard let row = self.row else { return }
        if self.quantity < ShoppingCart.maxAmount {
            self.quantity += 1
            self.updateQuantity(at: row)
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
        guard let row = self.row else { return false }
        DispatchQueue.main.async {
            self.updateQuantity(at: row)
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let row = self.row else { return false }
        self.delegate?.makeRowVisible(row: row)
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
            self.cellView?.imageView?.imageView?.image = img
            return
        }

        self.cellView?.imageView?.activityIndicatorView?.startAnimating()
        self.task = Snabble.urlSession.dataTask(with: url) { data, _, error in
            self.task = nil
            DispatchQueue.main.async {
                self.cellView?.imageView?.activityIndicatorView?.stopAnimating()
            }
            guard let data = data, error == nil else {
                return
            }

            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    ShoppingCartTableCell.imageCache[imgUrl] = image
                    self.cellView?.imageView?.imageView?.image = image
                }
            }
        }
        self.task?.resume()
    }
}