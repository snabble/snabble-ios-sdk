//
//  ShopCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI

public struct ShopCellView: View {
    let shop: ShopProviding
    let distance: Double?

    @Binding var currentShop: ShopProviding?

    private var isCurrentShop: Bool {
        guard let currentShop = currentShop else {
            return false
        }
        return currentShop.id == shop.id
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(shop.name)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 0) {
                    AddressView(provider: shop)
                        .secondaryStyle()
                }
            }
            Spacer()
            if isCurrentShop {
                Text(key: "Snabble.Shop.Finder.youarehere")
                    .youAreHereStyle()
            } else {
                DistanceView(distance: distance)
                    .secondaryStyle()
            }
        }
    }
}

private struct Secondary: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(.gray)
    }
}

private struct YouAreHere: ViewModifier {
    func body(content: Content) -> some View {
        content
           .font(.footnote)
           .foregroundColor(Color.onAccent())
           .padding(.horizontal, 8)
           .padding(.vertical, 4)
           .background(Color.accent())
           .clipShape(Capsule())
    }
}

private extension View {
    func youAreHereStyle() -> some View {
        modifier(YouAreHere())
    }

    func secondaryStyle() -> some View {
        modifier(Secondary())
    }
}
