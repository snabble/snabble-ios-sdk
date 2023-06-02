//
//  InvoiceLoginModel.swift
//  
//
//  Created by Uwe Tilemann on 01.06.23.
//

import Foundation
import Combine
import SnabbleCore

public final class InvoiceLoginModel: ObservableObject {
    private var paymentDetail: PaymentMethodDetail? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    var project: Project?
    @Published var isValid: Bool = false
    @Published var username: String = ""
    @Published var password: String = ""

    public init(paymentDetail: PaymentMethodDetail? = nil, project: Project? = nil) {
        self.paymentDetail = paymentDetail
        self.project = project
        
    }
    func delete() {
        print("*** TODO: implement delete() function in class InvoiceLoginModel.")
    }

    func save() async throws {
        print("*** TODO: implement save() function in class InvoiceLoginModel.")
    }

}

extension InvoiceLoginModel {
    public var userName: String? {
        if let detail = paymentDetail, case .invoiceByLogin(let data) = detail.methodData {
            return data.username
        }
        return nil
    }

    public var imageName: String? {
        return paymentDetail?.imageName
    }
}

/// CustomerCardLoginProcessor provides the logic to get customer card info using a login service
public final class InvoiceLoginProcessor: LoginProcessor, ObservableObject {
    let invoiceLoginModel: InvoiceLoginModel

    /// subscribe to this Publisher to start your login process
    public var actionPublisher = PassthroughSubject<[String: Any]?, Never>()

    init(invoiceLoginModel: InvoiceLoginModel) {
        
        self.invoiceLoginModel = invoiceLoginModel

        super.init(loginModel: invoiceLoginModel as? Loginable)
    }
        
    private var loginPublisher: Future<String, LoginError> {
        Future { [weak self] promise in
            guard let strongSelf = self, strongSelf.invoiceLoginModel.isValid else {
                return promise(.failure(.loginFailed))
            }
            
            let credentials = CustomerLoyaltyCredentials(username: strongSelf.invoiceLoginModel.username, password: strongSelf.invoiceLoginModel.password)
            
            strongSelf.invoiceLoginModel.project?.getCustomerLoyaltyInfo(with: credentials) { result in
                switch result {
                case .success(let info):
                    promise(.success(info.loyaltyCardNumber))
                case .failure:
                    promise(.failure(.loginFailed))
                }
            }
        }
    }
    
    public override func login() {
        loginPublisher
            .receive(on: RunLoop.main)
            .replaceError(with: "")
            .sink(receiveValue: { [weak self] string in
                guard let self = self else { return }

                print("loginPublisher \(String(describing: self.loginModel?.username)) received: \(string)")
            })
            .store(in: &cancellables)
    }
}
