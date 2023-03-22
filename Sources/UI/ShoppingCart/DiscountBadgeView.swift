//
//  DiscountBadgeView.swift
//  
//
//  Created by Uwe Tilemann on 21.03.23.
//

import SwiftUI

extension UserDefaults {
    private enum Keys {
        static let displayBadgedDiscount = "displayDiscountMode"
    }
    
    class var displayBadgedDiscount: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.displayBadgedDiscount)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.displayBadgedDiscount)
            UserDefaults.standard.synchronize()
        }
    }
}

private struct DiscountBadgeKey: EnvironmentKey {
    static let defaultValue = UserDefaults.displayBadgedDiscount
}

extension EnvironmentValues {
    var drawDiscountBadge: Bool {
        get { self[DiscountBadgeKey.self] }
        set {
            self[DiscountBadgeKey.self] = newValue
            UserDefaults.displayBadgedDiscount = newValue
        }
    }
}

extension View {
    func drawDiscountBadge(_ flag: Bool) -> some View {
        environment(\.drawDiscountBadge, flag)
    }
}

struct DiscountBadgeView: View {
    let discount: String
    
    let showBadge: Bool
    let showBadgeLabel: Bool
    let showPercentValue: Bool
    
    init(discount: String, showBadge: Bool = true, showBadgeLabel: Bool = true, showPercentValue: Bool = true) {
        self.discount = discount
        self.showBadge = showBadge
        self.showBadgeLabel = showBadgeLabel
        self.showPercentValue = showPercentValue
    }
    
    var body: some View {
        ZStack {
            if let image = Asset.image(named: "SnabbleSDK/icon-discount") {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.red)
                    .shadow(radius: 4, x: 0, y: 2)
            }
            Image(systemName: "percent")
                .font(Font.title.weight(.bold))
                .foregroundColor(.white)
                .opacity(0.33)
            Text(discount)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.66), radius: 2)
        }
    }
}

