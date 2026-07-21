//
//  AppState.swift
//  Snabble Sample App
//
//  Created by Uwe Tilemann on 02.03.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI
import CoreLocation

import SnabbleCore

@Observable
@MainActor
final class AppState {
    var project: Project?
    var shops: [Shop] = []
    var checkedInShop: Shop?

    init() { }
}

extension AppState: CheckInManagerDelegate {
    nonisolated func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop) {
        Task { @MainActor [self] in checkedInShop = shop }
    }

    nonisolated func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop) {
        Task { @MainActor [self] in checkedInShop = nil }
    }

    nonisolated func checkInManager(_ checkInManager: CheckInManager, locationAuthorizationNotGranted authorizationStatus: CLAuthorizationStatus) {}
    nonisolated func checkInManager(_ checkInManager: CheckInManager, locationAccuracyNotSufficient accuracyAuthorization: CLAccuracyAuthorization) {}
    nonisolated func checkInManager(_ checkInManager: CheckInManager, didFailWithError error: Error) {}
}
