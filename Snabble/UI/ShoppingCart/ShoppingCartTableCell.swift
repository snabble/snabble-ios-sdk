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

class ShoppingCartTableCell: UITableViewCell {

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
    
    private var item: CartItem!
    private var quantity = 0
    private weak var delegate: ShoppingCartTableDelegate!
    private var task: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.minusButton.makeBorderedButton()
        self.plusButton.makeBorderedButton()

        let mono10 = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        self.priceLabel.font = mono10
        self.quantityLabel.font = mono10

        self.quantityLabel.backgroundColor = SnabbleAppearance.shared.config.primaryColor
        self.quantityLabel.layer.cornerRadius = 2
        self.quantityLabel.layer.masksToBounds = true
        self.quantityLabel.textColor = SnabbleAppearance.shared.config.secondaryColor

        self.quantityInput.tintColor = SnabbleAppearance.shared.config.primaryColor
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
    }

    func setCartItem(_ item: CartItem, row: Int, delegate: ShoppingCartTableDelegate) {
        self.delegate = delegate
        self.item = item
        self.quantity = item.weight ?? item.quantity

        let product = item.product
        self.nameLabel.text = product.name
        self.subtitleLabel.text = product.subtitle

        self.minusButton.tag = row
        self.plusButton.tag = row
        self.quantityInput.tag = row

        self.minusButton.isHidden = product.weightDependent
        self.plusButton.isHidden = product.type == .preWeighed

        let weightEntry = product.type == .userMustWeigh
        self.quantityInput.isHidden = !weightEntry
        self.quantityWidth.constant = weightEntry ? 50 : 0
        self.quantityInput.text = "\(item.quantity)"

        if weightEntry {
            self.plusButton.backgroundColor = SnabbleAppearance.shared.config.primaryColor
            // FIXME("replace w/ checkmark icon")
            self.plusButton.setImage(UIImage.fromBundle("icon-close")?.recolored(with: SnabbleAppearance.shared.config.secondaryColor), for: .normal)
        } else {
            self.plusButton.backgroundColor = SnabbleAppearance.shared.config.buttonBackgroundColor
            self.plusButton.setImage(UIImage.fromBundle("icon-plus"), for: .normal)
        }

        self.showQuantity()

        self.loadImage()
    }

    private func updateQuantity(at row: Int) {
        if self.quantity == 0 && self.item.product.type == .singleItem {
            self.delegate.confirmDeletion(at: row)
            return
        }

        self.item.quantity = self.quantity
        self.delegate.cart.setQuantity(self.quantity, at: row)
        self.delegate.updateTotals()

        self.showQuantity()
    }

    private func showQuantity() {
        guard let ean = EAN.parse(self.item.scannedCode) else {
            return
        }

        let showWeight = ean.hasEmbeddedWeight
        let price = self.item.total

        let gram = showWeight ? "g" : ""
        self.quantityLabel.text = "\(self.quantity)\(gram)"

        let total = Price.format(price)
        if showWeight {
            let single = Price.format(self.item.product.price)
            self.priceLabel.text = "× \(single)/kg = \(total)"
        } else {
            if self.quantity == 1 {
                self.priceLabel.text = total
            } else {
                let itemPrice = Price.format(self.item.product.priceWithDeposit)
                self.priceLabel.text = "× \(itemPrice) = \(total)"
            }
        }
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
        
        spinner.startAnimating()
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
