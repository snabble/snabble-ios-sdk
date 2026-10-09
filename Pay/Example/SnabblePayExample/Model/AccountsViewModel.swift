//
//  AccountsViewModel.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//
import Foundation
import SnabblePay
import SnabbleLogger

@Observable
@MainActor
class AccountsViewModel {
    private var snabblePay: SnabblePay {
        return .shared
    }

    var accounts: [Account]? {
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
    var accountCheck: Account.Check?
    var ordered: [Account]?
    
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

    var selectedAccountModel: AccountViewModel? {
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

    func startAccountCheck() {
        Task {
            do {
                accountCheck = try await snabblePay.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE")
                selectedAccountModel?.refresh()
                ErrorHandler.shared.error = nil
            } catch let error as SnabblePay.Error {
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Start Account Check")
            } catch {
                ErrorHandler.shared.error = ErrorInfo(error: .unexpected(error), action: "Start Account Check")
            }
        }
    }

    func loadAccounts() {
        Task {
            do {
                accounts = try await snabblePay.accounts()
                selectedAccountModel?.refresh()
                ErrorHandler.shared.error = nil
            } catch let error as SnabblePay.Error {
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Loading Accounts")
            } catch {
                ErrorHandler.shared.error = ErrorInfo(error: .unexpected(error), action: "Loading Accounts")
            }
        }
    }

    func delete(account: Account) {
        Task {
            do {
                let deleted = try await snabblePay.deleteAccount(withId: account.id)
                Logger.shared.debug("Account deleted: \(deleted.id)")
                loadAccounts()
            } catch let error as SnabblePay.Error {
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Loading Accounts")
            } catch {
                ErrorHandler.shared.error = ErrorInfo(error: .unexpected(error), action: "Loading Accounts")
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
