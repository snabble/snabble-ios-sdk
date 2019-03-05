//
//  ShoppingCartTableCell.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

protocol ShoppingCartTableDelegate: class {
    func confirmDeletion(at row: Int)
    func updateTotals()

    var cart: ShoppingCart { get }
}

final class ShoppingCartTableCell: UITableViewCell {

    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var quantityInput: UITextField!

    @IBOutlet weak var quantityWidth: NSLayoutConstraint!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var textMargin: NSLayoutConstraint!

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    private var quantity = 0
    private var item: CartItem!
    private var lineItems: [CheckoutInfo.LineItem]?

    private weak var delegate: ShoppingCartTableDelegate!
    private var task: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.minusButton.makeBorderedButton()
        self.plusButton.makeBorderedButton()

        let mono10 = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        self.priceLabel.font = mono10
        self.quantityLabel.font = mono10

        self.quantityLabel.backgroundColor = SnabbleUI.appearance.primaryColor
        self.quantityLabel.layer.cornerRadius = 2
        self.quantityLabel.layer.masksToBounds = true
        self.quantityLabel.textColor = SnabbleUI.appearance.secondaryColor

        self.quantityInput.tintColor = SnabbleUI.appearance.primaryColor
        self.quantityInput.delegate = self

        self.minusButton.setImage(UIImage.fromBundle("icon-minus"), for: .normal)
        self.productImage.image = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.task?.cancel()
        self.task = nil
        self.productImage.image = nil
        self.imageWidth.constant = 44
        self.textMargin.constant = 8

        self.item = nil
        self.lineItems = nil
    }

    func setCartItem(_ item: CartItem, _ lineItems: [CheckoutInfo.LineItem], row: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate
        self.item = item
        self.lineItems = lineItems
        self.quantity = item.quantity

        let product = item.product
        self.nameLabel.text = product.name
        self.subtitleLabel.text = product.subtitle

        self.minusButton.tag = row
        self.plusButton.tag = row
        self.quantityInput.tag = row

        self.priceLabel.isHidden = false
        self.minusButton.isHidden = !item.editable
        self.plusButton.isHidden = !item.editable

        let weightEntry = product.type == .userMustWeigh
        self.quantityInput.isHidden = !weightEntry
        self.quantityWidth.constant = weightEntry ? 50 : 0
        self.quantityInput.text = "\(item.quantity)"

        if weightEntry {
            self.plusButton.backgroundColor = SnabbleUI.appearance.primaryColor
            // FIXME("replace w/ checkmark icon")
            self.plusButton.setImage(UIImage.fromBundle("icon-close")?.recolored(with: SnabbleUI.appearance.secondaryColor), for: .normal)
        } else {
            self.plusButton.backgroundColor = SnabbleUI.appearance.buttonBackgroundColor
            self.plusButton.setImage(UIImage.fromBundle("icon-plus"), for: .normal)
        }

        self.showQuantity()

        // suppress display when price == 0
        if self.item.price == 0 {
            self.priceLabel.isHidden = true
            self.minusButton.isHidden = true
            self.plusButton.isHidden = true
        }

        self.loadImage()
    }

    private func updateQuantity(at row: Int) {
        if self.quantity == 0 && self.item.product.type != .userMustWeigh {
            self.delegate.confirmDeletion(at: row)
            return
        }

        self.item.quantity = self.quantity
        self.delegate.cart.setQuantity(self.quantity, at: row)
        self.delegate.updateTotals()

        self.lineItems = nil
        self.showQuantity()
    }

    private func showQuantity() {
        let showWeight = self.item.product.referenceUnit?.hasDimension == true || self.item.product.type == .userMustWeigh

        let encodingUnit = self.item.encodingUnit ?? self.item.product.encodingUnit
        let symbol = encodingUnit?.display ?? ""
        let gram = showWeight ? symbol : ""
        self.quantityLabel.text = "\(self.item.effectiveQuantity)\(gram)"

        let formatter = PriceFormatter(SnabbleUI.project)

//        if let lineItem = self.lineItems?.first {
//            self.priceLabel.text = formatter.format(lineItem.totalPrice)
//        } else {
//            self.priceLabel.text = self.item.priceDisplay(formatter)
//        }
        self.priceLabel.text = self.item.priceDisplay(formatter)
    }

    private func loadImage() {
        guard
            let imgUrl = self.item.product.imageUrl,
            let url = URL(string: imgUrl)
        else {
            self.imageWidth.constant = 0
            self.textMargin.constant = 0
            return
        }

        self.imageWidth.constant = 44
        self.textMargin.constant = 8
        self.setNeedsLayout()

        self.spinner.startAnimating()

        self.task = URLSession.shared.dataTask(with: url) { data, response, error in
            self.task = nil
            DispatchQueue.main.async() {
                self.spinner.stopAnimating()
            }
            guard let data = data, error == nil else {
                return
            }

            if let image = UIImage(data: data) {
                DispatchQueue.main.async() {
                    self.productImage.image = image
                }
            }
        }
        self.task?.resume()
    }

    @IBAction func minusButtonTapped(_ button: UIButton) {
        if self.quantity > 0 {
            self.quantity -= 1
            self.updateQuantity(at: button.tag)
        }
    }

    @IBAction func plusButtonTapped(_ button: UIButton) {
        if self.item.product.type == .userMustWeigh {
            // treat this as the "OK" button
            self.quantityInput.resignFirstResponder()
            return
        }
        
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

        let newText = text.replacingCharacters(in: range, with: string)
        let qty = Int(newText) ?? 0

        if qty > ShoppingCart.maxAmount || (range.location == 0 && string == "0") {
            return false
        }

        self.quantity = qty
        self.updateQuantity(at: textField.tag)
        return true
    }

}
