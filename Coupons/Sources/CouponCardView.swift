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
        .padding(.vertical)
        .task {
            viewModel.loadImage()
        }
    }

    
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            viewModel.newView
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .font(.headline)
                .foregroundColor(foregroundColor)
                .minimumScaleFactor(0.85)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(foregroundColor.opacity(0.7))
            }

            if let text = viewModel.text {
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.projectPrimary())
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            Text(viewModel.validUntil)
                .font(.caption2)
                .foregroundColor(foregroundColor.opacity(0.6))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
