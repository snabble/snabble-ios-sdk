//
//  SepaAcceptModel.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import Combine
import Observation
import SnabbleCore

@Observable
public final class SepaAcceptModel {
    /// subscribe to this Publisher to  process
    public var actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    
    let process: CheckoutProcess
    let paymentDetail: PaymentMethodDetail?
    
    init(process: CheckoutProcess, paymentDetail: PaymentMethodDetail? = nil) {
        self.process = process
        self.paymentDetail = paymentDetail
    }
    
    public var markup: String? {
        guard let markup = process.paymentPreauthInformation?.markup,
              let body = markup.replacingOccurrences(of: "+", with: " ").removingPercentEncoding else {
            return nil
        }
        
        let head = """
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
        <style type="text/css">
            pre { font-family: -apple-system, sans-serif; font-size: 15px; white-space: pre-wrap; }
            body { padding: 8px 8px }
            * { font-family: -apple-system, sans-serif; font-size: 15px; word-wrap: break-word }
            *, a { color: #000 }
            h1 { font-size: 22px }
            h2 { font-size: 17px }
            h4 { font-weight: normal; color: #3c3c43; opacity: 0.6 }
            @media (prefers-color-scheme: dark) {
                a, h4, * { color: #fff }
            }
        </style>
    </head>
    <body>
"""
        let trail = """
    </body>
</html>
"""
        return head + body + trail
    }
}

private struct EmptyDecodable: Decodable {}

extension SepaAcceptModel {
    
    public func accept() async throws {

        guard let urlString = process.links.authorizePayment?.href else {
            return
        }
        let project = SnabbleCI.project
       
        let data = [ "mandateReference": process.paymentPreauthInformation?.mandateIdentification ]

        project.request(.post, urlString, body: data, timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (_ result: Result<EmptyDecodable, SnabbleError>, response) in
                                
                if response?.statusCode == 204 { // No Content
                
                    if let detail = self.paymentDetail, case .payoneSepa(let data) = detail.methodData, let mandateReference = self.process.paymentPreauthInformation?.mandateIdentification {
                        var sepaData = data
                         
                        sepaData.mandateReference = mandateReference
                        sepaData.mandateMarkup = self.process.paymentPreauthInformation?.markup
                        
                        let newDetail = PaymentMethodDetail(sepaData)

                        PaymentMethodDetails.save(newDetail)
                        PaymentMethodDetails.remove(detail)
                    }
                } else {
                    self.actionPublisher.send(["action": "authorizingFailed"])
                }
            }
        }
    }
    
    public func decline() async throws {
        
        process.abort(SnabbleCI.project) { (result: Result<CheckoutProcess, SnabbleError>) in
            switch result {
            case .success:
                Snabble.clearInFlightCheckout()

            case .failure:
                self.actionPublisher.send(["action": "cancelPaymentFailed"])
            }
        }
    }
}
