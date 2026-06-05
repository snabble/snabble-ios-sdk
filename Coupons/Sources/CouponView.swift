//
//  CouponView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 05.06.26.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents

public struct CouponView: View {
    @State var couponModel: CouponViewModel
    
    public init(coupon: Coupon, shouldActivateCoupon: @escaping (Coupon) -> Bool) {
        self.couponModel = CouponViewModel(coupon: coupon, shouldActivateCoupon: shouldActivateCoupon)
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
            .buttonStyle(ProjectPrimaryButtonStyle())
            
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
            couponModel.loadImage()
        }
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Coupons.title"))
    }
}
