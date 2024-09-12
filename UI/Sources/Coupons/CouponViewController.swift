//
//  CouponViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import SnabbleCore
import SwiftUI
import SnabbleAssetProviding

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
            .buttonStyle(PrimaryButtonStyle())
            
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

/// A UIViewController wrapping SwiftUI's ShoppingCartView
open class CouponViewController: UIHostingController<CouponView> {
    public weak var delegate: CouponViewControllerDelegate?

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

    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
    }
}

extension CouponViewController: CouponViewModelDelegate {
    func couponViewModel(_ couponViewModel: CouponViewModel, shouldActivateCoupon coupon: Coupon) -> Bool {
        delegate?.couponViewController(self, shouldActivateCoupon: coupon) ?? true
    }
}

public protocol CouponViewControllerDelegate: AnyObject {
    func couponViewController(_ couponViewController: CouponViewController, shouldActivateCoupon coupon: Coupon) -> Bool
}
