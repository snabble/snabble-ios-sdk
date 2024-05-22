//
//  AccountsViewModel.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//
import Foundation
import Combine
import SnabblePay
import SnabbleLogger

class AccountsViewModel: ObservableObject {
    private var snabblePay: SnabblePay {
        return .shared
    }

    @Published var accounts: [Account]? {
        didSet {
            if let selectedID = UserDefaults.selectedAccount, let account = accounts?.first(where: { $0.id.rawValue == selectedID }) {
                selectedAccount = account
            } else if let first = accounts?.first {
                selectedAccount = first
            } else {
                selectedAccount = nil
            }
        }
    }
    @Published var accountCheck: Account.Check?
    @Published var ordered: [Account]?
    
    private func accountStack() -> [Account]? {
        guard let selected = selectedAccount else {
            return accounts
        }
        var array = [Account]()
        array.append(selected)
        if let unselected = self.unselected {
            array.append(contentsOf: unselected)
        }
        return array.reversed()
    }

    @Published var selectedAccountModel: AccountViewModel? {
        willSet {
            if let model = selectedAccountModel {
                model.autostart = false
            }
        }
        didSet {
            if let model = selectedAccountModel {
                UserDefaults.selectedAccount = model.account.id.rawValue
                model.autostart = true
            }
            self.ordered = accountStack()
        }
    }
    
    var selectedAccount: Account? {
        didSet {
            if let account = selectedAccount {
                self.selectedAccountModel = AccountViewModel(account: account)
            } else {
                self.selectedAccountModel = nil
            }
        }
    }
    func isSelected(index: Int) -> Bool {
        guard let account = selectedAccount, let first = ordered?.firstIndex(where: { $0 == account }) else {
            return false
        }
        return index == first
    }
    
    var onDestructiveAction: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()

    func startAccountCheck() {
        snabblePay.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE") { [weak self] result in
            switch result {
            case .success(let accountCheck):
                self?.accountCheck = accountCheck
                if let model = self?.selectedAccountModel {
                    model.refresh()
                }
                ErrorHandler.shared.error = nil

            case .failure(let error):
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Start Account Check")
            }
        }
    }

    func loadAccounts() {
        snabblePay.accounts { [weak self]  result in
            switch result {
            case .success(let accounts):
                self?.accounts = accounts
                if let model = self?.selectedAccountModel {
                    model.refresh()
                }
                ErrorHandler.shared.error = nil
                
            case .failure(let error):
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Loading Accounts")
            }
       }
    }
    func delete(account: Account) {
        snabblePay.deleteAccount(withId: account.id) { [weak self] result in
            switch result {
            case .success(let account):
                Logger.shared.debug("Account deleted: \(account.id)")
                self?.loadAccounts()
                
            case .failure(let error):
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Loading Accounts")

            }
            
        }
    }
}

extension AccountsViewModel {    
    var unselected: [Account]? {
        guard let selected = selectedAccount else {
            return accounts
        }
        return accounts?.filter({ $0 != selected })
    }
   
    var canSelect: Bool {
        guard let model = selectedAccountModel else {
            return true
        }
        return model.canSelect
    }
}
