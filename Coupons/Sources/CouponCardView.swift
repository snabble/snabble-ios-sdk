//
//  CouponCardView.swift
//  Snabble
//
//  Swift 6.2 Migration - SwiftUI replacement for CouponCollectionViewCell
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents

public struct CouponCardView: View {
    let coupon: Coupon
    @State private var viewModel: CouponViewModel

    public init(coupon: Coupon) {
        self.coupon = coupon
        self._viewModel = State(initialValue: CouponViewModel(coupon: coupon))
    }

    private var foregroundColor: Color {
        if let hex = coupon.colors?.foreground {
            return Color(hex: hex)
        }
        return Color(.label)
    }

    private var backgroundColor: Color {
        if let hex = coupon.colors?.background {
            return Color(hex: hex)
        }
        return Color(.systemBackground)
    }

    public var body: some View {
        VStack(spacing: 0) {
            imageSection
            contentSection
        }
        .background(backgroundColor)
        .cardStyle()
    }

    private var imageSection: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            } else {
                ProgressView()
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .font(.headline)
                .foregroundColor(foregroundColor)
                .lineLimit(nil)
                .minimumScaleFactor(0.75)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(foregroundColor)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 16)

            if let text = viewModel.text {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.projectPrimary())
                    .lineLimit(nil)
                    .minimumScaleFactor(0.75)
            }

            Text(viewModel.validUntil)
                .font(.caption)
                .foregroundColor(foregroundColor)
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
