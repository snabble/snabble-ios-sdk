//
//  GermanIdCardViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class GermanIdCardViewController: UIViewController {

    @IBOutlet private var saveButton: UIButton!
    @IBOutlet private var textField: UITextField!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var blurbLabel: UILabel!

    public weak var navigationDelegate: PaymentMethodNavigationDelegate?
    
    private var keyboardObserver: KeyboardObserver!
    private var toolbarHeight: CGFloat = 0

    private let settingsKey = "germanIdCardBirthdate"

    private var savedBirthDate: String? {
        get {
            return UserDefaults.standard.string(forKey: self.settingsKey)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: self.settingsKey)
            if let val = newValue {
                AgeVerification.setUsersBirthday(String(val.prefix(6)))
            } else {
                AgeVerification.setUsersBirthday(nil)
            }
        }
    }

    public init() {
        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.ageVerification.title".localized()

        self.keyboardObserver = KeyboardObserver(handler: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.blurbLabel.text = "Snabble.ageVerification.explanation".localized()

        self.saveButton.makeSnabbleButton()
        self.saveButton.isEnabled = false
        self.saveButton.setTitle("Snabble.Save".localized(), for: .normal)

        if let birthdate = self.savedBirthDate {
            self.textField.text = self.savedBirthDate
            self.saveButton.isEnabled = self.isValidBirthDate(birthdate)
        }

        self.textField.placeholder = "Snabble.ageVerification.placeholder".localized()
        self.textField.delegate = self
        let toolbar = self.textField.addDoneButton()
        self.toolbarHeight = toolbar.frame.height

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    private struct Birthdate: Codable {
        let dayOfBirth: String
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        self.savedBirthDate = self.textField.text

        guard
            let appUserId = SnabbleAPI.appUserId?.userId,
            let birthday = AgeVerification.getUsersBirthday()
        else {
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let project = SnabbleUI.project
        let birthdate = Birthdate(dayOfBirth: formatter.string(from: birthday))
        #warning("remove DIY url")
        project.request(.patch, "/apps/users/\(appUserId)", body: birthdate) { request in
            guard let request = request else {
                Log.error("no request for user's age")
                return
            }

            project.perform(request) { (result: Result<Birthdate, SnabbleError>) in
                switch result {
                case .success(let birthdate):
                    Log.debug("saved dayOfBirth: \(birthdate)")
                    self.goBack()
                case .failure(let error):
                    print("\(error)")
                    let alert = UIAlertController(title: "Fehler beim Speichern", message: "Geburtsdatum konnte nicht gespeichert werden.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func goBack() {
        if SnabbleUI.implicitNavigation {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.navigationDelegate?.goBack()
        }
    }
}

extension GermanIdCardViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else {
            return false
        }

        let newText = text.replacingCharacters(in: range, with: string)

        let isValid = self.isValidBirthDate(newText)

        self.saveButton.isEnabled = isValid
        return true
    }

    private func isValidBirthDate(_ str: String) -> Bool {
        let digits = str.compactMap { Int(String($0)) }

        guard digits.count == 7 else {
            return false
        }

        let multipliers = [ 7, 3, 1, 7, 3, 1 ]
        var checksum = 0
        for (index, multiplier) in multipliers.enumerated() {
            checksum += (digits[index] * multiplier) % 10
        }

        let checkdigit = checksum % 10
        return checkdigit == digits[6]
    }
}

extension GermanIdCardViewController: KeyboardHandling {
    func keyboardWillShow(_ info: KeyboardInfo) {
        let kbHeight = info.endFrame.height + self.toolbarHeight

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbHeight, right: 0)
        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets

        var viewFrame = self.view.frame
        viewFrame.size.height -= kbHeight

        if !viewFrame.contains(self.textField.frame.origin) {
            let scrollPoint = CGPoint(x: 0, y: self.textField.frame.origin.y - kbHeight)
            UIView.animate(withDuration: info.animationDuration) {
                self.scrollView.contentOffset = scrollPoint
            }
        }
    }

    func keyboardWillHide(_ info: KeyboardInfo) {
        UIView.animate(withDuration: info.animationDuration) {
            self.scrollView.contentOffset = .zero
            self.scrollView.contentInset = .zero
            self.scrollView.scrollIndicatorInsets = .zero
        }
    }

}
