//
//  Toaster.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-10-21.
//

import SwiftUI

@Observable
public class Toaster {
    public var toast: Toast?
    
    public init() {
        self.toast = nil
    }
}
