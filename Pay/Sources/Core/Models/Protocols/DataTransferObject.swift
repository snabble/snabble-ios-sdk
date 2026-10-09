//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-24.
//

import Foundation

protocol FromDTO {
    associatedtype DTO
    init(fromDTO dto: DTO)
}

protocol ToModel {
    associatedtype Model
    func toModel() -> Model
}

protocol ToDTO {
    associatedtype DTO
    func toDTO() -> DTO
}

extension Array where Element: ToModel {
    func toModel() -> [Element.Model] {
        map {
            $0.toModel()
        }
    }
}
