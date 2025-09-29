//
//  SepaEditViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

protocol SepaEditViewControllerDelegate: AnyObject {
    func sepaEditViewControllerDidSave(iban: String)
}

// tags for the input fields, determines tabbing order (starts at `name`)
private enum InputField: Int {
    case name = 0
    case country = 1
    case number = 2
}

public final class SepaEditViewController: UIViewController {
    private let hintLabel = UILabel()
    private let nameLabel = UILabel()
    private let nameField = UITextField()
    private let ibanLabel = UILabel()
    private let ibanCountryField = UITextField()
    private let ibanNumberField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let scrollView = UIScrollView()

    private var detail: PaymentMethodDetail?
    private var candidate: OriginCandidate?
    private var keyboardObserver: KeyboardObserver?
    private weak var analyticsDelegate: AnalyticsDelegate?
    weak var delegate: SepaEditViewControllerDelegate?

    public init(_ detail: PaymentMethodDetail?, _ analyticsDelegate: AnalyticsDelegate?) {
        self.detail = detail
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: nil)

        self.title = Asset.localizedString(forKey: "Snabble.Payment.SEPA.title")
        self.keyboardObserver = KeyboardObserver(handler: self)
    }

    public init(_ candidate: OriginCandidate, _ analyticsDelegate: AnalyticsDelegate?) {
        self.candidate = candidate

        super.init(nibName: nil, bundle: nil)

        self.title = Asset.localizedString(forKey: "Snabble.Payment.SEPA.title")
        self.keyboardObserver = KeyboardObserver(handler: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        view.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)

        saveButton.makeSnabbleButton()
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle(Asset.localizedString(forKey: "Snabble.save"), for: .normal)
        saveButton.addTarget(self, action: #selector(self.saveButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(saveButton)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.numberOfLines = 0
        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.hint")
        scrollView.addSubview(hintLabel)

        self.setupKeyboard(self.nameField)
        self.setupKeyboard(self.ibanCountryField)
        self.setupKeyboard(self.ibanNumberField)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.name")
        scrollView.addSubview(nameLabel)

        ibanLabel.translatesAutoresizingMaskIntoConstraints = false
        ibanLabel.numberOfLines = 0
        ibanLabel.font = .preferredFont(forTextStyle: .body)
        ibanLabel.adjustsFontForContentSizeCategory = true
        ibanLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.iban")
        scrollView.addSubview(ibanLabel)

        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.tag = InputField.name.rawValue
        nameField.keyboardType = .alphabet
        nameField.autocapitalizationType = .words
        nameField.font = .preferredFont(forTextStyle: .body)
        nameField.adjustsFontForContentSizeCategory = true
        nameField.delegate = self
        scrollView.addSubview(nameField)

        ibanCountryField.translatesAutoresizingMaskIntoConstraints = false
        ibanCountryField.tag = InputField.country.rawValue
        ibanCountryField.text = "DE"
        ibanCountryField.font = .preferredFont(forTextStyle: .body)
        ibanCountryField.adjustsFontForContentSizeCategory = true
        ibanCountryField.delegate = self
        ibanCountryField.setContentHuggingPriority(.required, for: .horizontal)
        ibanCountryField.setContentCompressionResistancePriority(.required, for: .horizontal)
        scrollView.addSubview(ibanCountryField)

        ibanNumberField.translatesAutoresizingMaskIntoConstraints = false
        ibanNumberField.tag = InputField.number.rawValue
        ibanNumberField.keyboardType = .numberPad
        ibanNumberField.returnKeyType = .done
        let smallPhone = UIScreen.main.bounds.width <= 320
        ibanNumberField.clearButtonMode = smallPhone ? .never : .always
        ibanNumberField.placeholder = self.placeholderFor("DE")
        ibanNumberField.font = .preferredFont(forTextStyle: .body)
        ibanNumberField.adjustsFontForContentSizeCategory = true
        ibanNumberField.delegate = self
        scrollView.addSubview(ibanNumberField)

        let toolbar = ibanNumberField.addDoneButton()
        let abcButton = UIBarButtonItem(title: "ABC/123", style: .plain, target: self, action: #selector(self.toggleKeyboard(_:)))
        toolbar.items?.insert(abcButton, at: 0)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            hintLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            hintLabel.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -16),

            nameLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            nameLabel.bottomAnchor.constraint(equalTo: nameField.topAnchor, constant: -8),

            nameField.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            nameField.bottomAnchor.constraint(equalTo: ibanLabel.topAnchor, constant: -16),

            ibanLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            ibanLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            ibanLabel.bottomAnchor.constraint(equalTo: ibanCountryField.topAnchor, constant: -8),
            ibanLabel.bottomAnchor.constraint(equalTo: ibanNumberField.topAnchor, constant: -8),

            ibanCountryField.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            ibanCountryField.trailingAnchor.constraint(equalTo: ibanNumberField.leadingAnchor, constant: -4),

            ibanNumberField.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            ibanNumberField.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16)
        ])
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let detail = self.detail {
            self.hintLabel.text = Asset.localizedString(forKey: "Snabble.SEPA.editingHint")

            self.saveButton.isHidden = true

            self.nameField.text = String(repeating: "•", count: 25)
            self.nameField.isEnabled = false

            let iban = detail.displayName
            self.ibanNumberField.text = String(iban.suffix(iban.count - 2))
            self.ibanNumberField.isEnabled = false
            self.ibanNumberField.clearButtonMode = .never

            self.ibanCountryField.text = String(iban.prefix(2))
            self.ibanCountryField.isEnabled = false

            let trash: UIImage? = UIImage(systemName: "trash")
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

            self.hintLabel.text = Asset.localizedString(forKey: "Snabble.SEPA.scoTransferHint")
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if nameField.isEnabled {
            self.nameField.becomeFirstResponder()
        }
        self.analyticsDelegate?.track(.viewPaymentMethodDetail)
    }

    @objc private func saveButtonTapped(_ sender: Any) {
        guard
            let country = self.ibanCountryField.text,
            let number = self.ibanNumberField.text,
            let name = self.nameField.text
        else {
            return
        }

        for input in [ self.nameField, self.ibanCountryField, self.ibanNumberField ] where input.isFirstResponder == true {
            input.resignFirstResponder()
        }

        let iban = self.sanitzeIban(country + number)
        let valid = self.verifyIban(iban)

        var showError = false
        if !valid {
            self.ibanNumberField.textColor = .systemRed
            self.ibanLabel.textColor = .systemRed
            self.ibanLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.invalidIBAN")
            showError = true
        }
        if name.isEmpty {
            self.nameField.textColor = .systemRed
            self.nameLabel.textColor = .systemRed
            self.nameLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.invalidName")
            showError = true
        }
        if country.isEmpty {
            self.ibanCountryField.textColor = .systemRed
            self.ibanLabel.textColor = .systemRed
            self.ibanLabel.text = Asset.localizedString(forKey: "Snabble.Payment.SEPA.missingCountry")
            showError = true
        }

        if showError {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                Task { @MainActor in
                    self.fadeText(self.ibanLabel, Asset.localizedString(forKey: "Snabble.Payment.SEPA.iban"))
                    self.fadeText(self.nameLabel, Asset.localizedString(forKey: "Snabble.Payment.SEPA.name"))
                }
            }
        }

        if valid && !name.isEmpty {
            if let cert = Snabble.shared.certificates.first, let sepaData = SepaData(cert.data, name, iban) {
                let detail = PaymentMethodDetail(sepaData)
                PaymentMethodDetails.save(detail)
                self.delegate?.sepaEditViewControllerDidSave(iban: iban)
                self.analyticsDelegate?.track(.paymentMethodAdded(detail.rawMethod.displayName))

                if let promote = self.candidate?.links?.promote.href {
                    self.promoteCandidate(promote, sepaData.encryptedPaymentData)
                } else {
                    self.goBack()
                }
            } else {
                let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.SEPA.encryptionError"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))

                self.present(alert, animated: true)
            }
        }
    }

    private struct Empty: Decodable {}

    private func promoteCandidate(_ url: String, _ encryptedOrigin: String) {
        let project = SnabbleCI.project

        let origin = [ "origin": encryptedOrigin ]
        project.request(.post, url, body: origin, timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (_: Result<Empty, SnabbleError>, response) in
                if response?.statusCode == 201 { // created
                    Task { @MainActor in
                        self.goBack()
                    }
                }
            }
        }
    }

    private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteButtonTapped(_ sender: Any) {
        guard let detail = self.detail else {
            return
        }

        let alert = UIAlertController(title: nil, message: Asset.localizedString(forKey: "Snabble.Payment.Delete.message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            PaymentMethodDetails.remove(detail)
            self.analyticsDelegate?.track(.paymentMethodDeleted(detail.rawMethod.displayName))
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel, handler: nil))

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
        let country = self.ibanCountryField.text ?? ""
        let ibanText = self.ibanNumberField.text ?? ""
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
            if let country = self.ibanCountryField.text {
                iban = self.formattedIban(country, iban)
            }
            textField.text = iban
            self.markTextfields()
        default: break
        }
    }

    private func placeholderFor(_ country: String) -> String {
        return IBAN.placeholder(country)
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
                if let country = self.ibanCountryField.text {
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
        let placeholder = IBAN.placeholder(country)
        
        return self.formatIban(placeholder, iban)
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

extension SepaEditViewController: KeyboardHandling {
    public func keyboardWillShow(_ info: KeyboardInfo) {
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: info.keyboardHeight, right: 0)
    }

    public func keyboardWillHide(_ info: KeyboardInfo) {
        scrollView.contentInset = .zero
    }
}
