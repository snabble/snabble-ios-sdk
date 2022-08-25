//
//  OpeningHoursViewModel.swift
//  Snabble
//
//  Created by Uwe Tilemann on 25.08.22.
//

import Foundation
import SwiftUI

public protocol OpeningHourProvider {
    var day: String? { get }
    var hour: String? { get }
}

struct OpeningHourViewModel: OpeningHourProvider {
    let day: String?
    let hour: String?

    init(forWeekday weekday: String, withSpecification specification: [OpeningHoursSpecification]) {
        let filteredSpecification = specification.filter { $0.dayOfWeek == weekday }
        if let dayKey = filteredSpecification.first?.dayOfWeek/*.lowercased()*/ {
            self.day = Asset.localizedString(forKey: dayKey) + ":"
        } else {
            self.day = nil
        }
        self.hour = filteredSpecification.map { "\($0.opens.prefix(5)) – \($0.closes.prefix(5))" }.joined(separator: "\n")
    }
}

public struct OpeningHourView: View, Swift.Identifiable {
    var viewModel: OpeningHourViewModel
    public let id = UUID()
    
    @ViewBuilder
    var day: some View {
        if let day = viewModel.day {
            Text(key: day)
                .lineLimit(2)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var hour: some View {
        if let hour = viewModel.hour {
            Text(key: hour)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            EmptyView()
        }
    }

    public var body: some View {
        HStack(alignment: .top) {
            day
            hour
        }
    }
}
public struct OpeningView: View {
    var shop: ShopProviding

    var views: [OpeningHourView] {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            .map {
                OpeningHourViewModel(forWeekday: $0, withSpecification: shop.openingHoursSpecification)
            }
            .map {
                OpeningHourView(viewModel: $0)
            }
    }
    
    public var body: some View {
        VStack {
            Text(key: "Snabble.Shop.Detail.openingHours")
                .padding(.top, 4)
                .padding(.bottom, 4)
            
            VStack(alignment: .trailing) {
                
                ForEach(views, id: \.id) {
                    $0
                }
            }
        }
        .font(.footnote)
    }
}
