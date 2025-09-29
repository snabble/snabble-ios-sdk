//
//  CouponsViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit
import SnabbleCore
import SnabbleAssetProviding

public protocol CouponsViewControllerDelegate: AnyObject {
    func couponsViewController(_ viewController: CouponsViewController, didSelectCoupon coupon: Coupon)
}

public final class CouponsViewController: UICollectionViewController {
    private(set) weak var emptyLabel: UILabel?

    public weak var delegate: CouponsViewControllerDelegate?

    public var coupons: [Coupon] = [] {
        didSet {
            update(with: coupons)
        }
    }

    public init(coupons: [Coupon]) {
        self.coupons = coupons
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView(collectionView)
        configureEmptyLabel(on: collectionView)
        update(with: coupons)

        // Modern trait change registration for iOS 17+
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.update(with: self.coupons)
            }
        }
    }

    private func configureCollectionView(_ collectionView: UICollectionView) {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.register(CouponCollectionViewCell.self)
    }

    private func configureEmptyLabel(on collectionView: UICollectionView) {
        let emptyLabel = UILabel()
        emptyLabel.text = Asset.localizedString(forKey: "Snabble.Coupons.none")
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = false
        collectionView.backgroundView = emptyLabel
        self.emptyLabel = emptyLabel
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update(with: coupons)
    }

    private func update(with coupons: [Coupon]) {
        emptyLabel?.isHidden = !coupons.isEmpty
        collectionView.reloadData()
    }
}

// MARK: - collectionView
extension CouponsViewController {
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        coupons.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusable(CouponCollectionViewCell.self, for: indexPath)

        let viewModel = CouponViewModel(coupon: coupons[indexPath.row])
        cell.configure(with: viewModel)

        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let coupon = coupons[indexPath.row]
        delegate?.couponsViewController(self, didSelectCoupon: coupon)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CouponsViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemCount = collectionView.numberOfItems(inSection: indexPath.section)

        if itemCount == 1 {
            let horizontalPadding: CGFloat = 25
            let fullWidth = collectionView.bounds.width - horizontalPadding * 2
            return CGSize(width: fullWidth, height: 355)
        } else {
            return CGSize(width: 265, height: 355)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
}
