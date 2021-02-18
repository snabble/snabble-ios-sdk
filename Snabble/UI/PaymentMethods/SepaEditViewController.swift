//
//  SepaEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

// tags for the input fields, determines tabbing order (starts at `name`)
private enum InputField: Int {
    case name = 0
    case country = 1
    case number = 2
}

public final class SepaEditViewController: UIViewController {

    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameField: UITextField!
    @IBOutlet private weak var ibanLabel: UILabel!
    @IBOutlet private weak var ibanCountryField: UITextField!
    @IBOutlet private weak var ibanNumberField: UITextField!
    @IBOutlet private weak var saveButton: UIButton!

    private var detail: PaymentMethodDetail?
    private var candidate: OriginCandidate?
    private let showFromCart: Bool
    private weak var analyticsDelegate: AnalyticsDelegate?

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?

    public init(_ detail: PaymentMethodDetail?, _ showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.showFromCart = showFromCart
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Payment.SEPA.Title".localized()
    }

    public init(_ candidate: OriginCandidate, _ analyticsDelegate: AnalyticsDelegate?) {
        self.candidate = candidate
        self.showFromCart = false

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Payment.SEPA.Title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.hintLabel.text = "Snabble.Payment.SEPA.hint".localized()

        self.saveButton.makeSnabbleButton()
        self.saveButton.setTitle("Snabble.Save".localized(), for: .normal)

        self.setupKeyboard(self.nameField)
        self.setupKeyboard(self.ibanCountryField)
        self.setupKeyboard(self.ibanNumberField)

        self.nameLabel.text = "Snabble.Payment.SEPA.Name".localized()
        self.ibanLabel.text = "Snabble.Payment.SEPA.IBAN".localized()

        self.nameField.tag = InputField.name.rawValue
        self.nameField.keyboardType = .alphabet
        self.nameField.autocapitalizationType = .words

        self.ibanCountryField.tag = InputField.country.rawValue
        self.ibanCountryField.text = "DE"

        self.ibanNumberField.tag = InputField.number.rawValue
        self.ibanNumberField.keyboardType = .numberPad
        self.ibanNumberField.returnKeyType = .done
        let smallPhone = UIScreen.main.bounds.width <= 320
        self.ibanNumberField.clearButtonMode = smallPhone ? .never : .always
        self.ibanNumberField.placeholder = self.placeholderFor("DE")

        self.ibanNumberField.addDoneButton()
        let toolbar = self.ibanNumberField.addDoneButton()
        let abcButton = UIBarButtonItem(title: "ABC/123", style: .plain, target: self, action: #selector(self.toggleKeyboard(_:)))
        toolbar.items = [ abcButton ] + toolbar.items!

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let detail = self.detail {
            self.hintLabel.text = "Snabble.SEPA.editingHint".localized()

            self.saveButton.isHidden = true

            self.nameField.text = String(repeating: "•", count: 25)
            self.nameField.isEnabled = false

            let iban = detail.displayName
            self.ibanNumberField.text = String(iban.suffix(iban.count - 2))
            self.ibanNumberField.isEnabled = false
            self.ibanNumberField.clearButtonMode = .never

            self.ibanCountryField.text = String(iban.prefix(2))
            self.ibanCountryField.isEnabled = false

            let trash = UIImage.fromBundle("SnabbleSDK/icon-trash")
            let deleteButton = UIBarButtonItem(image: trash, style: .plain, target: self, action: #selector(self.deleteButtonTapped(_:)))
            self.navigationItem.rightBarButtonItem = deleteButton
        } else if let originIban = self.candidate?.origin {
            self.nameField.returnKeyType = .done

            let country = String(originIban.prefix(2))
            self.ibanCountryField.text = country
            self.ibanCountryField.isEnabled = false

            let iban = self.formattedIban(country, originIban)
            self.ibanNumberField.text = iban
            self.ibanNumberField.isEnabled = false

            self.hintLabel.text = "Snabble.SEPA.scoTransferHint".localized()
        } else {
            self.nameField.becomeFirstResponder()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    @IBAction private func saveButtonTapped(_ sender: Any) {
        guard
            let country = self.ibanCountryField?.text,
            let number = self.ibanNumberField?.text,
            let name = self.nameField?.text
        else {
            return
        }

        for input in [ self.nameField, self.ibanCountryField, self.ibanNumberField ] where input?.isFirstResponder == true {
            input?.resignFirstResponder()
        }

        let iban = self.sanitzeIban(country + number)
        let valid = self.verifyIban(iban)

        var showError = false
        if !valid {
            self.ibanNumberField.textColor = .systemRed
            self.ibanLabel.textColor = .systemRed
            self.ibanLabel.text = "Snabble.Payment.SEPA.InvalidIBAN".localized()
            showError = true
        }
        if name.isEmpty {
            self.nameField.textColor = .systemRed
            self.nameLabel.textColor = .systemRed
            self.nameLabel.text = "Snabble.Payment.SEPA.InvalidName".localized()
            showError = true
        }
        if country.isEmpty {
            self.ibanCountryField.textColor = .systemRed
            self.ibanLabel.textColor = .systemRed
            self.ibanLabel.text = "Snabble.Payment.SEPA.missingCountry".localized()
            showError = true
        }

        if showError {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                self.fadeText(self.ibanLabel, "Snabble.Payment.SEPA.IBAN".localized())
                self.fadeText(self.nameLabel, "Snabble.Payment.SEPA.Name".localized())
            }
        }

        if valid && !name.isEmpty {
            if let cert = SnabbleAPI.certificates.first, let sepaData = SepaData(cert.data, name, iban) {
                let detail = PaymentMethodDetail(sepaData)
                PaymentMethodDetails.save(detail)
                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))

                if let promote = self.candidate?.links?.promote.href {
                    self.promoteCandidate(promote, sepaData.encryptedPaymentData)
                } else {
                    self.goBack()
                }
            } else {
                let alert = UIAlertController(title: nil, message: "Snabble.SEPA.encryptionError".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))

                self.present(alert, animated: true)
            }
        }
    }

    private struct Empty: Decodable {}

    private func promoteCandidate(_ url: String, _ encryptedOrigin: String) {
        let project = SnabbleUI.project

        let origin = [ "origin": encryptedOrigin ]
        project.request(.post, url, body: origin, timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (_: Result<Empty, SnabbleError>, response) in
                if response?.statusCode == 201 { // created
                    self.goBack()
                }
            }
        }
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            if self.showFromCart {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if self.showFromCart {
                self.navigationDelegate?.goBackToCart()
            } else {
                self.navigationDelegate?.goBack()
            }
        }
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Snabble.Payment.delete.message".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(detail.rawMethod.displayName))
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    private func setupKeyboard(_ textField: UITextField) {
        textField.keyboardType = .namePhonePad
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .never
        textField.returnKeyType = .next
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 6
        textField.delegate = self
    }

    // see https://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
    private func verifyIban(_ iban: String) -> Bool {
        var rawBytes = Array(iban.utf8)
        while rawBytes.count < 4 {
            rawBytes.append(0)
        }

        let bytes = rawBytes[4 ..< rawBytes.count] + rawBytes[0 ..< 4]

        let check = bytes.reduce(0) { result, digit in
            let int = Int(digit)
            return int > 64 ? (100 * result + int - 55) % 97 : (10 * result + int - 48) % 97
        }

        return check == 1
    }

    @objc private func toggleKeyboard(_ sender: Any) {
        let type: UIKeyboardType = self.ibanNumberField.keyboardType == .namePhonePad ? .numberPad : .namePhonePad
        self.ibanNumberField.resignFirstResponder()
        self.ibanNumberField.keyboardType = type
        self.ibanNumberField.becomeFirstResponder()
    }

    private func sanitzeIban(_ iban: String) -> String {
        let trimmed = iban.replacingOccurrences(of: " ", with: "")
        return trimmed.uppercased()
    }

    private func markTextfields() {
        let country = self.ibanCountryField?.text ?? ""
        let ibanText = self.ibanNumberField?.text ?? ""
        let iban = self.sanitzeIban(ibanText)

        let letters = CharacterSet.uppercaseLetters
        let range = country.rangeOfCharacter(from: letters)
        let countryValid = country.isEmpty || range != nil
        self.markTextfield(self.ibanCountryField, self.ibanLabel, countryValid)

        let numberValid = iban.isEmpty || verifyIban(country + iban)
        self.markTextfield(self.ibanNumberField, self.ibanLabel, numberValid)
    }

    private func markTextfield(_ textField: UITextField, _ label: UILabel, _ valid: Bool) {
        textField.textColor = valid ? .label : .systemRed
        label.textColor = valid ? .label : .systemRed

        let borderColor: UIColor = valid ? .clear : .systemRed
        textField.layer.borderColor = borderColor.cgColor
    }

    private func fadeText(_ label: UILabel, _ text: String) {
        UIView.transition(with: label,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { label.text = text },
                          completion: nil)
    }
}

extension SepaEditViewController: UITextFieldDelegate {

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        switch textField.tag {
        case InputField.name.rawValue:
            self.markTextfield(self.nameField, self.nameLabel, !text.isEmpty)
        case InputField.country.rawValue: // country field - uppercase
            textField.text = text.uppercased()
            self.markTextfields()
            self.ibanNumberField.placeholder = self.placeholderFor(textField.text!)
        case InputField.number.rawValue: // number field - uppercase and check validity
            var iban = self.sanitzeIban(text)
            if let country = self.ibanCountryField?.text {
                iban = self.formattedIban(country, iban)
            }
            textField.text = iban
            self.markTextfields()
        default: break
        }
    }

    private func placeholderFor(_ country: String) -> String {
        return IBAN.placeholder(country) ?? "IBAN"
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextTextField = self.view.viewWithTag(nextTag) as? UITextField, nextTextField.isEnabled {
            nextTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else {
            return false
        }

        if string.isEmpty { // deletion
            return true
        }

        let newText = text.replacingCharacters(in: range, with: string)

        let alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIKLJMNOPQRSTUVWXYZ"
        let letters = CharacterSet(charactersIn: alpha)
        let alphanumerics = CharacterSet(charactersIn: alpha + "0123456789")

        switch textField.tag {
        case InputField.country.rawValue: // country field
            if newText.count > 2 {
                return false
            }
            return string.rangeOfCharacter(from: letters) != nil

        case InputField.number.rawValue: // number field
            let ok = string.rangeOfCharacter(from: alphanumerics) != nil
            if ok {
                if let country = self.ibanCountryField?.text {
                    let formatted = self.formattedIban(country, self.sanitzeIban(newText))
                    textField.text = formatted
                } else {
                    textField.text = newText
                }
            }
            return false

        default:
            return true
        }
    }

    private func formattedIban(_ country: String, _ iban: String) -> String {
        var iban = iban
        if iban.hasPrefix(country) {
            let index = iban.index(iban.startIndex, offsetBy: country.count)
            iban = String(iban[index...])
        }
        if let placeholder = IBAN.placeholder(country) {
            return self.formatIban(placeholder, iban)
        } else {
            return iban
        }
    }

    private func formatIban(_ pattern: String, _ text: String) -> String {
        let replacementChar = pattern.prefix(1)
        var formatted = ""

        var patternIndex = pattern.startIndex
        var textIndex = text.startIndex

        while patternIndex < pattern.endIndex && textIndex < text.endIndex {
            let nextIndex = pattern.index(after: patternIndex)
            let str = pattern[patternIndex ..< nextIndex]
            patternIndex = nextIndex

            if str != replacementChar {
                formatted += str
            } else {
                let nextIndex = text.index(after: textIndex)
                formatted += text[textIndex..<nextIndex]
                textIndex = nextIndex
            }

        }

        return formatted
    }
}

// stuff that's only used by the RN wrapper
extension SepaEditViewController: ReactNativeWrapper {
    public func setDetail(_ detail: PaymentMethodDetail) {
        self.detail = detail

        self.candidate = nil
    }
}
