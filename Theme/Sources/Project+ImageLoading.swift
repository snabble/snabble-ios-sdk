//
//  Project+ImageLoading.swift
//  Snabble
//
//  Created by Uwe Tilemann on 29.07.25.
//

import UIKit

import SnabbleCore

extension Project {
    public func fetchImage(urlString: String) async -> UIImage? {
        await withCheckedContinuation { continuation in
            request(.get, urlString, timeout: 3) { request in
                guard let request = request else {
                    return continuation.resume(returning: nil)
                }
                let session = Snabble.urlSession
                let task = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        Log.error("Error landing page image download: \(error)")
                        return continuation.resume(returning: nil)
                    }
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard statusCode == 200, let data = data else {
                        Log.error("Error landing page image download for \(name): \(statusCode)")
                        return continuation.resume(returning: nil)
                    }
                    continuation.resume(returning: UIImage(data: data))
                }
                task.resume()
            }
        }
    }
}
