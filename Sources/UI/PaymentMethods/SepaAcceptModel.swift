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

extension SepaAcceptModel {
    public func accept(completion: @escaping (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) async throws {
                
        print("will authorize")
//        do {
//
//        } catch {
//            //  throw an error
//        }
    }
}

