//
//  Project+ImageLoading.swift
//  Snabble
//
//  Created by Uwe Tilemann on 29.07.25.
//

import UIKit

import SnabbleCore

extension Project {
    func fetchImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
        request(.get, urlString, timeout: 3) { request in
            guard let request = request else {
                return completion(nil)
            }
            let session = Snabble.urlSession
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    Log.error("Error landing page image download: \(error)")
                    return completion(nil)
                }
                
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard statusCode == 200, let data = data else {
                    Log.error("Error landing page image download for \(name): \(statusCode)")
                    return completion(nil)
                }
                completion(UIImage(data: data))
            }
            task.resume()
        }
    }
}
