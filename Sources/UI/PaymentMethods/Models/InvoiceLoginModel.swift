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
    public static let invalid = InvoiceLoginInfo(username: "#$§*!", contactPersonID: "")
    
    public let username: String
    public let contactPersonID: String
    
    public func isValid(username: String) -> Bool {
        guard username != InvoiceLoginInfo.invalid.username else {
            return false
        }
        return username == self.username
    }
}

public struct InvoiceLoginCredentials: Encodable {
    public let username: String
    public let password: String
}

extension Project {
    public func getUserLoginInfo(with credentials: InvoiceLoginCredentials,
                                 completion: @escaping (Result<InvoiceLoginInfo, SnabbleError>) -> Void) {
        let url = "https://api.snabble-testing.io/\(self.id)/external-billing/credentials/auth"
        
        do {
            let data = try JSONEncoder().encode(credentials)

            self.request(.post, url, body: data, timeout: 2) { request in
                guard let request = request else {
                    return completion(.failure(SnabbleError.noRequest))
                }

                self.perform(request, completion)
            }
        } catch {
            print(error)
            completion(.failure(SnabbleError.invalid))
        }
    }
}

public final class InvoiceLoginModel: LoginViewModel {
    @Published public var isLoggedIn = false
    @Published public var isSaved = false

    private var paymentDetail: PaymentMethodDetail?
    
    @Published public var loginInfo: InvoiceLoginInfo? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        didSet {
            if let info = self.loginInfo, info.isValid(username: self.username) {
                self.isValid = true
                self.isLoggedIn = true
            } else if self.loginInfo == nil {
                self.isLoggedIn = false
                self.isValid = false
                self.isSaved = false
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
        guard let personID = loginInfo?.contactPersonID, !password.isEmpty else {
            return
        }
        
        if let cert = Snabble.shared.certificates.first,
           let invoiceData = InvoiceByLoginData(cert: cert.data, username, password, personID, project?.id ?? SnabbleCI.project.id) {

            let detail = PaymentMethodDetail(invoiceData)
            PaymentMethodDetails.save(detail)

            paymentDetail = detail
            DispatchQueue.main.async {
                self.isSaved = true
            }
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

/// CustomerCardLoginProcessor provides the logic to get customer card info using a login service
public final class InvoiceLoginProcessor: LoginProcessor, ObservableObject {
    @Published public var invoiceLoginModel: InvoiceLoginModel
    @Published public var isWaiting = false
    
    var cancellables = Set<AnyCancellable>()

    init(invoiceLoginModel: InvoiceLoginModel) {
        self.invoiceLoginModel = invoiceLoginModel
        super.init(loginModel: invoiceLoginModel)
    }
    
    private var loginPublisher: Future<InvoiceLoginInfo, LoginError> {
        Future { [weak self] promise in
            guard let strongSelf = self, strongSelf.invoiceLoginModel.isValid else {
                return promise(.failure(.loginFailed))
            }
            
            let credentials = InvoiceLoginCredentials(username: strongSelf.invoiceLoginModel.username, password: strongSelf.invoiceLoginModel.password)
                                          
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
    
    public override func login() {
        isWaiting = true
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
    
    public override func remove() {
        invoiceLoginModel.reset()
    }
    public func save() async throws {
        try await invoiceLoginModel.save()
    }
}
