//
//  CouponsViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit

public protocol CouponsViewControllerDelegate: AnyObject {
    func couponsViewController(_ viewController: CouponsViewController, didSelectCoupon coupon: Coupon)
}

public final class CouponsViewController: UICollectionViewController {
    private(set) weak var emptyLabel: UILabel?

    public weak var delegate: CouponsViewControllerDelegate?

    private let cellWidth: CGFloat = 265
    private let cellHeight: CGFloat = 355

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
        view.clipsToBounds = false
        configureCollectionView(collectionView)
        configureEmptyLabel(on: collectionView)
        update(with: coupons)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: cellHeight)
        ])
    }

    private func configureCollectionView(_ collectionView: UICollectionView) {
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.register(CouponCollectionViewCell.self)
    }

    private func configureEmptyLabel(on collectionView: UICollectionView) {
        let emptyLabel = UILabel()
        emptyLabel.text = L10n.Snabble.Coupons.none
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
        CGSize(width: cellWidth, height: cellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
}
