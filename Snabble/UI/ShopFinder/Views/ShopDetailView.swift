//
//  ShopDetailView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import SwiftUI

public struct ShopDetailView: View {
    var shop: Shop
    
    public var body: some View {
        Text(shop.name)
    }
}
