//
//  OpeningHoursView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 25.08.22.
//

import Foundation
import SwiftUI

public extension ShopProviding {
    var openingHoursViewModel: [OpeningHourViewModel] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            .map {
                OpeningHourViewModel(forWeekday: $0, withSpecification: openingHoursSpecification)
            }
    }
}

public struct OpeningHoursView: View {
    var shop: ShopProviding
    @Environment(\.locale) private var locale: Locale
    
    public var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(keyed: "Snabble.Shop.Detail.openingHours")
                .font(.headline)

            VStack(alignment: .trailing, spacing: 2) {
                ForEach(shop.openingHoursViewModel, id: \.id) { viewModel in
                    HStack(alignment: .top) {
                        if let day = viewModel.day {
                            Text(day)
                                .lineLimit(2)
                        } else {
                            EmptyView()
                        }
                        if let hour = viewModel.hour {
                            Text(hour)
                                .lineLimit(2)
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
            .font(.footnote)
        }
    }
}
