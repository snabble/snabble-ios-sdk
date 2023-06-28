//
//  InvoiceLoginModel.swift
//  
//
//  Created by Uwe Tilemann on 01.06.23.
//

import Foundation
import Combine
import SnabbleCore

public struct InvoiceLoginInfo: Decodable {
    public static let invalid = InvoiceLoginInfo()
    
    public let username: String?
    public let contactPersonID: String?
    
    public init(username: String? = nil, contactPersonID: String? = nil) {
        self.username = username
        self.contactPersonID = contactPersonID
    }
    public func isValid(username: String?) -> Bool {
        guard username != InvoiceLoginInfo.invalid.username else {
            return false
        }
        return username == self.username
    }
    public static func isValid(loginInfo: InvoiceLoginInfo?) -> Bool {
        guard let info = loginInfo else {
            return false
        }
        return info.isValid(username: info.username)
    }
}

public struct InvoiceLoginCredentials: Encodable {
    public let username: String
    public let password: String
}

extension Project {
    public var externalBillingAuthURLString: String {
        return "\(Snabble.shared.environment.urlString)/\(self.id)/external-billing/credentials/auth"
    }

    public func getUserLoginInfo(with credentials: InvoiceLoginCredentials,
                                 completion: @escaping (Result<InvoiceLoginInfo, SnabbleError>) -> Void) {
        do {
            let data = try JSONEncoder().encode(credentials)

            self.request(.post, externalBillingAuthURLString, body: data, timeout: 2) { request in
                guard let request = request else {
                    return completion(.failure(SnabbleError.noRequest))
                }

                self.perform(request, completion)
            }
        } catch {
            completion(.failure(SnabbleError.invalid))
        }
    }
}

public final class InvoiceLoginModel: LoginViewModel {
    @Published public var isLoggedIn = false

    private var paymentDetail: PaymentMethodDetail?
    
    @Published public var loginInfo: InvoiceLoginInfo? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        didSet {
            if let info = self.loginInfo, info.isValid(username: self.username) {
                self.isLoggedIn = true
            } else if InvoiceLoginInfo.isValid(loginInfo: self.loginInfo) == false {
                if let info = self.loginInfo, info.username == InvoiceLoginInfo.invalid.username {
                    self.errorMessage = Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.Error.wrongCredentials")
                }
                self.isLoggedIn = false
            }
       }
    }
    
    var project: Project?

    public init(paymentDetail: PaymentMethodDetail? = nil, project: Project? = nil) {
        self.paymentDetail = paymentDetail
        self.project = project

        super.init()
        
        if let name = paymentUsername {
            self.username = name
        }
    }

    func reset() {
        guard let detail = paymentDetail else {
            return
        }
        PaymentMethodDetails.remove(detail)

        self.username = ""
        self.password = ""
        self.paymentDetail = nil
        self.loginInfo = nil
    }

    func save() async throws {
        guard let personID = loginInfo?.contactPersonID else {
            return
        }
        guard let username = username, let password = password else {
            return
        }
        if let cert = Snabble.shared.certificates.first,
           let invoiceData = InvoiceByLoginData(cert: cert.data, Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title"), username, password, personID, project?.id ?? SnabbleCI.project.id) {

            let detail = PaymentMethodDetail(invoiceData)
            PaymentMethodDetails.save(detail)

            paymentDetail = detail
        } else {
            throw PaymentMethodError.encryptionError
        }
    }
}

extension InvoiceLoginModel {
    public var paymentUsername: String? {
        if let detail = paymentDetail, case .invoiceByLogin(let data) = detail.methodData {
            return data.username
        }
        return nil
    }
    public var paymentContactPersonID: String? {
        if let detail = paymentDetail, case .invoiceByLogin(let data) = detail.methodData {
            return data.contactPersonID
        }
        return nil
    }
}
extension InvoiceLoginModel {
    public var imageName: String? {
        return paymentDetail?.imageName
    }
}

/// InvoiceLoginProcessor provides the logic to get customer card info using a login service
public final class InvoiceLoginProcessor: LoginProcessing, ObservableObject {
    
    var loginModel: Loginable? {
        return self.invoiceLoginModel
    }
        
    @Published public var invoiceLoginModel: InvoiceLoginModel
    @Published public var isWaiting = false
    
    var cancellables = Set<AnyCancellable>()

    init(invoiceLoginModel: InvoiceLoginModel) {
        self.invoiceLoginModel = invoiceLoginModel
    }
    
    private var loginPublisher: Future<InvoiceLoginInfo, LoginError> {
        Future { [weak self] promise in
            guard let strongSelf = self, strongSelf.invoiceLoginModel.isValid else {
                return promise(.failure(.loginFailed))
            }
            
            guard let username = strongSelf.invoiceLoginModel.username,
                  let password = strongSelf.invoiceLoginModel.password else {
                
                return promise(.failure(.loginFailed))
            }
            let credentials = InvoiceLoginCredentials(username: username, password: password)
                                          
            strongSelf.invoiceLoginModel.project?.getUserLoginInfo(with: credentials) { result in
                switch result {
                case .success(let info):
                    promise(.success(info))
                case .failure:
                    promise(.failure(.loginFailed))
                }
            }
        }
    }
    
    public func login() {
        isWaiting = true
        self.invoiceLoginModel.errorMessage = ""
        
        loginPublisher
            .receive(on: RunLoop.main)
            .replaceError(with: InvoiceLoginInfo.invalid)
            .sink(receiveValue: { [weak self] loginInfo in
                guard let strongSelf = self else { return }

                strongSelf.invoiceLoginModel.loginInfo = loginInfo
                strongSelf.isWaiting = false
            })
            .store(in: &cancellables)
    }
    
    public func remove() {
        invoiceLoginModel.reset()
    }
    
    public func save() async throws {
        try await invoiceLoginModel.save()
    }
}
