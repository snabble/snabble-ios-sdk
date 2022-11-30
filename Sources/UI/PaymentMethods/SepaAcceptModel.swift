//
//  SepaAcceptModel.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import Combine
import SnabbleCore

public final class SepaAcceptModel: ObservableObject {
    /// subscribe to this Publisher to  process
    public var actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    
    let process: CheckoutProcess
    var poller: PaymentProcessPoller?
    
    init(process: CheckoutProcess) {
        self.process = process
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
        let trail  = """
    </body>
</html>
"""
        
        return head + body + trail
    }
}

fileprivate struct EmptyDecodable: Decodable {}
fileprivate struct EmptyEncodable: Encodable {}

extension SepaAcceptModel {
    
    func sepaAuthorize() {
        guard let urlString = process.links.authorizePayment?.href else {
            return
        }
        let project = SnabbleCI.project

        project.request(.post, urlString, body: EmptyEncodable(), timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (_ result : Result<EmptyDecodable, SnabbleError>, response) in
                
                print("result: \(result), status: \(String(describing: response?.statusCode))")
                
                if response?.statusCode == 204 { // No Content
                    self.waitForPaymentProcessing()
                } else {
                    self.actionPublisher.send(["action": "authorizingFailed"])
                }
            }
        }
    }
    private func waitForPaymentProcessing() {
        let project = SnabbleCI.project
        let poller = PaymentProcessPoller(process, project)

        poller.waitFor([.paymentSuccess]) { events in
            if events[.paymentSuccess] != nil {
                self.paymentFinished(process: poller.updatedProcess)
            } else {
                print("poller received: \(events)")
            }
        }

        self.poller = poller
    }

    private func paymentFinished(process: CheckoutProcess) {
        self.poller = nil

        print("paymentFinished - paymentState: \(process.paymentState)")
        actionPublisher.send(["action": "paymentFinished"])
        
//        let paymentDisplay = CheckoutStepsViewController(shop: shop,
//                                                         shoppingCart: shoppingCart,
//                                                         checkoutProcess: checkoutProcess)
//        paymentDisplay.paymentDelegate = delegate
//        self.navigationController?.pushViewController(paymentDisplay, animated: true)
    }

    public func accept(completion: () -> Void ) async throws {
        
        print("will authorize")
//        completion()
        sepaAuthorize()
//        do {
//
//        } catch {
//            //  throw an error
//        }
    }
}

