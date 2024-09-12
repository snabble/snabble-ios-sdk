//
//  ShopCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI
import SnabbleAssetProviding

public struct ShopCellView: View {
    let shop: ShopProviding
    @ObservedObject var viewModel: ShopsViewModel
    
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
            if viewModel.isCurrent(shop) {
                Text(keyed: "Snabble.Shop.Finder.youarehere")
                    .youAreHereStyle()
            } else {
                DistanceView(distance: viewModel.distance(from: shop))
                    .secondaryStyle()
            }
        }
    }
}

private struct Secondary: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color.named("Snabble.Shop.Finder.Secondary.foreground") ?? .systemGray)
    }
}

private struct YouAreHere: ViewModifier {
    func body(content: Content) -> some View {
        content
           .font(.footnote)
           .foregroundColor(Color.named("Snabble.Shop.Finder.YouAreHere.foreground") ?? .onProjectPrimary())
           .padding(.horizontal, 8)
           .padding(.vertical, 4)
           .background(Color.named("Snabble.Shop.Finder.YouAreHere.background") ?? .projectPrimary())
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
