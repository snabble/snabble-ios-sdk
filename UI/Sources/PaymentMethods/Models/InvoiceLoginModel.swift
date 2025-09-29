//
//  InvoiceLoginModel.swift
//  
//
//  Created by Uwe Tilemann on 01.06.23.
//

import Foundation
import Combine
import Observation
import SnabbleCore
import SnabbleAssetProviding

public struct InvoiceLoginInfo: Decodable, Sendable {
    public let username: String?
    public let contactPersonID: String?
    
    public init(username: String? = nil, contactPersonID: String? = nil) {
        self.username = username
        self.contactPersonID = contactPersonID
    }
    public func isValid(username: String?) -> Bool {
        guard let username = username, !username.isEmpty else {
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
        return "\(Snabble.shared.environment.apiURLString)/\(self.id)/external-billing/credentials/auth"
    }

    public func getUserLoginInfo(with credentials: InvoiceLoginCredentials,
                                 completion: @escaping @Sendable (Result<InvoiceLoginInfo, SnabbleError>) -> Void) {
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

public final class InvoiceLoginModel: LoginViewModel, @unchecked Sendable {
    public var isLoggedIn = false

    private var paymentDetail: PaymentMethodDetail?

    public var loginInfo: InvoiceLoginInfo? {
        didSet {
            if let info = loginInfo, info.isValid(username: username) {
                isLoggedIn = true
            } else {
                isLoggedIn = false
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
@Observable @MainActor
public final class InvoiceLoginProcessor: LoginProcessing {

    var loginModel: Loginable? {
        return self.invoiceLoginModel
    }

    public var invoiceLoginModel: InvoiceLoginModel
    public var isWaiting = false
    
    var cancellables = Set<AnyCancellable>()

    init(invoiceLoginModel: InvoiceLoginModel) {
        self.invoiceLoginModel = invoiceLoginModel
    }
    
    public func login() {
        isWaiting = true
        self.invoiceLoginModel.errorMessage = nil

        // Extrahiere alle benötigten Werte vor dem Task
        guard invoiceLoginModel.isValid,
              let username = invoiceLoginModel.username,
              let password = invoiceLoginModel.password,
              let project = invoiceLoginModel.project else {
            self.invoiceLoginModel.errorMessage = Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.Error.wrongCredentials")
            return
        }

        let credentials = InvoiceLoginCredentials(username: username, password: password)

        Task {
            do {
                let loginInfo = try await withCheckedThrowingContinuation { continuation in
                    project.getUserLoginInfo(with: credentials) { @Sendable result in
                        continuation.resume(with: result.mapError { _ in LoginError.loginFailed })
                    }
                }
                self.isWaiting = false
                self.invoiceLoginModel.loginInfo = loginInfo
            } catch {
                self.isWaiting = false
                self.invoiceLoginModel.errorMessage = Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.Error.wrongCredentials")
            }
        }
    }
    
    public func remove() {
        invoiceLoginModel.reset()
    }
    
    public func save() async throws {
        try await invoiceLoginModel.save()
    }
}
