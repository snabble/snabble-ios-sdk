//
//  PriceFormatter+UI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//
//  Price formatting stuff

import Foundation

extension PriceFormatter {
    public static func format(_ price: Int) -> String {
        return PriceFormatter.format(SnabbleUI.project, price)
    }

    public static func format(_ project: Project, _ price: Int) -> String {
        let fmt = PriceFormatter(project)
        return fmt.format(price)
    }

}
