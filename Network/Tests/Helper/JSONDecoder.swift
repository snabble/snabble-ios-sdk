//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import Foundation

var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
}
