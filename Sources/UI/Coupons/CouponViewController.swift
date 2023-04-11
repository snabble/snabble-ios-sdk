//
//  CouponViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import SnabbleCore
import SwiftUI

extension CouponViewModel {
    var buttonTitle: String {
        Asset.localizedString(forKey: coupon.isActivated ? "Snabble.Coupon.deactivate" : "Snabble.Coupon.activate")
    }
    
    @objc
    func activateCoupon() {
        Snabble.shared.couponManager.activate(coupon: coupon)
    }
    
    @objc
    func deactivateCoupon() {
        Snabble.shared.couponManager.deactivate(coupon: coupon)
    }

    @objc
    func toggleActivation() {
        if coupon.isActivated {
            self.deactivateCoupon()
        } else {
            self.activateCoupon()
        }
        self.objectWillChange.send()
    }
}

public struct CouponView: View {
    @ObservedObject var couponModel: CouponViewModel
    
    public init(coupon: Coupon) {
        self.couponModel = CouponViewModel(coupon: coupon)
    }
    
    @ViewBuilder
    var image: some View {
        if let image = couponModel.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
    
    @ViewBuilder
    var titleLabel: some View {
        Text(couponModel.title)
            .font(.title2)
    }
    
    @ViewBuilder
    var subtitleLabel: some View {
        if let text = couponModel.subtitle {
            Text(text)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    var disclaimerLabel: some View {
        if let text = couponModel.disclaimer {
            Text(text)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    var textLabel: some View {
        if let text = couponModel.text {
            Text(text)
                .font(.headline)
        }
    }

    @ViewBuilder
    var validityLabel: some View {
        Text(couponModel.validUntil)
            .font(.footnote)
    }

    @ViewBuilder
    var button: some View {
        VStack {
            Button(action: {
                couponModel.toggleActivation()
            }) {
                Text(couponModel.buttonTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButtonStyle())
            
            if couponModel.coupon.isActivated {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text(Asset.localizedString(forKey: "Snabble.Coupon.activated"))
                }
                .font(Font.subheadline.weight(.bold))
                .foregroundColor(.systemGreen)
            }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            image
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    titleLabel
                    subtitleLabel
                    disclaimerLabel
                    textLabel
                    validityLabel
                    button
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            _ = couponModel.loadImage { _ in
            }
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Coupons.title"))
    }
}

/// A UIViewController wrapping SwiftUI's ShoppingCartView
open class CouponViewController: UIHostingController<CouponView> {
    var viewModel: CouponViewModel {
        rootView.couponModel
    }

    public init(coupon: Coupon) {
        let rootView = CouponView(coupon: coupon)
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
