//
//  AppState.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore

@Observable
@MainActor
final class AppState {
    var project: Project?
    var shops: [Shop] = []
    var checkedInShop: Shop?
    
    init() { }
}
