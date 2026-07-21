//
//  CheckInState.swift
//  Snabble
//

import Observation

/// Observable check-in state for use with SwiftUI.
///
/// Access via `Snabble.shared.checkInManager.state`. SwiftUI views automatically
/// re-render when `shop` changes without needing a `.task` or `for await` loop.
@Observable
public final class CheckInState {
    /// The currently checked-in shop, or `nil` if not checked in.
    public private(set) var shop: Shop?

    init() {}

    func update(shop: Shop?) {
        self.shop = shop
    }
}
