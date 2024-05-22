//
//  AccountViewModel.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//
import Foundation
import Combine
import SnabblePay
import SnabbleLogger

class AccountViewModel: ObservableObject {
    private let snabblePay: SnabblePay = .shared

    let account: Account
    var autostart: Bool {
        didSet {
            if autostart == false {
                resetTimer()
            }
        }
    }

    private var refreshTimer: Timer?
    
    private var refreshDate: Date? {
        guard let token = self.token else {
            return session?.token.refreshAt
        }
        return token.refreshAt
    }
    
    private func resetTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        if autostart, let refreshAt = self.refreshDate {
            self.refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshAt.timeIntervalSince(.now), repeats: false) { _ in
                self.refreshToken()
            }
        }
    }

    init(account: Account, autostart: Bool = true) {
        self.account = account
        self.autostart = autostart
        
        if let name = UserDefaults.standard.string(forKey: account.id.rawValue) {
            self.customName = name
        } else {
            self.customName = account.name
        }
        self.needsReload = false
    }

    @Published var mandate: Account.Mandate? {
        didSet {
            if let mandateID = mandate?.id.rawValue, let html = mandate?.htmlText {
                UserDefaults.standard.set(html, forKey: mandateID)
            }
        }
    }
    @Published var needsReload: Bool
    
    var mandateState: Account.Mandate.State {
        guard let mandate = mandate else {
            return account.mandateState
        }
        return mandate.state
    }
    
    private var session: Session?
    @Published var token: Session.Token? {
        didSet {
            resetTimer()
            sessionUpdated.toggle()
        }
    }
        
    @Published var sessionUpdated = false
    @Published var customName: String {
        didSet {
            if !customName.isEmpty {
                UserDefaults.standard.set(customName, forKey: account.id.rawValue)
            } else {
                UserDefaults.standard.set(nil, forKey: account.id.rawValue)
            }
        }
    }
    var hasCustomName: Bool {
        if !customName.isEmpty, customName != account.name {
            return true
        }
        return false
    }
    var cancellables = Set<AnyCancellable>()

    func update(action: String, result: Result<Account.Mandate, SnabblePay.Error>) {
        switch result {
        case .success(let mandate):
            self.mandate = mandate
            if account.mandateState != mandate.state {
                Logger.shared.debug("Mandate State changed to: \(mandate.state)")
                if mandate.state != .pending {
                    needsReload.toggle()
                }
                self.objectWillChange.send()
            }
            
        case .failure(let error):
            ErrorHandler.shared.error = ErrorInfo(error: error, action: action)
        }
    }
    
    func createMandate() {
        if [.missing, .pending, .declined].contains(mandateState) {
            snabblePay.createMandate(forAccountId: account.id) { [weak self] result in
                self?.update(action: "Create Mandate", result: result)
            }
        } else {
            snabblePay.mandate(forAccountId: account.id) { [weak self] result in
                self?.update(action: "Request Mandate", result: result)
            }
        }
    }

    func decline(mandateId: Account.Mandate.ID) {
        snabblePay.declineMandate(withId: mandateId, forAccountId: account.id) { [weak self] result in
            self?.update(action: "Decline Mandate", result: result)
       }
    }

    func accept(mandateId: Account.Mandate.ID) {
        snabblePay.acceptMandate(withId: mandateId, forAccountId: account.id) { [weak self] result in
            self?.update(action: "Accept Mandate", result: result)
        }
    }

   private var isLoading = false

    private func startSession() {
        guard self.autostart, self.mandateState == .accepted else {
            return
        }
        isLoading = true
        
        snabblePay.startSession(withAccountId: account.id) { [weak self] result in
            self?.isLoading = false
            
            switch result {
            case .success(let session):
                self?.session = session
                self?.token = session.token
                
            case .failure(let error):
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Start Session")
            }
        }
    }

    private func refreshToken() {
        guard let session = self.session else {
            return
        }
        isLoading = true
        snabblePay.refreshToken(withSessionId: session.id) { [weak self] result in
            self?.isLoading = false
            
            switch result {
            case .success(let token):
                self?.token = token

            case .failure(let error):
                self?.token = nil
                self?.sleep()
                ErrorHandler.shared.error = ErrorInfo(error: error, action: "Refresh Token")
            }
        }
    }
}

extension AccountViewModel {
    var canSelect: Bool {
        return isLoading == false
    }
    
    var needsRefresh: Bool {
        guard self.autostart else {
            return false
        }
        guard let refreshAt = self.refreshDate else {
            return true
        }
        return refreshAt.timeIntervalSince(.now) <= 0
    }
    
    func sleep() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func refresh() {
        if needsRefresh {
            if self.session != nil {
                refreshToken()
            } else {
                startSession()
            }
        }
    }
}
