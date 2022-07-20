//
//  CouponsViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit
import Combine

public protocol CouponsViewControllerDelegate: AnyObject {
    func couponSelected(_ coupon: Coupon)
}

public final class CouponsViewController: UICollectionViewController {
    private var subscriptions = Set<AnyCancellable>()
    private var spinner = UIActivityIndicatorView()
    private var emptyMessage = UILabel()
    public weak var delegate: CouponsViewControllerDelegate?
    private var heightConstraint: NSLayoutConstraint?

    private let cellWidth: CGFloat = 265
    private var cellHeight: CGFloat = 0

    private(set) var coupons: [Coupon] = [] {
        didSet {
            updateCoupons()
        }
    }

    public init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .systemBackground
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)

        view.clipsToBounds = false
        collectionView.clipsToBounds = false

        collectionView.register(CouponCollectionViewCell.self, forCellWithReuseIdentifier: "couponCell")

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        emptyMessage.translatesAutoresizingMaskIntoConstraints = false
        emptyMessage.text = L10n.Snabble.Coupons.none
        view.addSubview(emptyMessage)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        heightConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true

        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification, object: nil)
            .sink { [weak self] _ in
                self?.updateCoupons()
            }
            .store(in: &subscriptions)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coupons = SnabbleSDK.CouponManager.shared.all(for: Snabble.shared.checkInManager.shop?.projectId) ?? []
    }

    private func updateCoupons() {
        self.emptyMessage.isHidden = !coupons.isEmpty

        cellHeight = maxCellHeight()
        heightConstraint?.constant = cellHeight
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    private func updateSpinner(_ loading: Bool) {
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    private func maxCellHeight() -> CGFloat {
        let sizingCell = CouponCollectionViewCell(frame: .zero)
        sizingCell.contentView.translatesAutoresizingMaskIntoConstraints = false
        var height: CGFloat = 0
        for coupon in coupons {
            sizingCell.prepareForReuse()
            let viewModel = CouponViewModel(coupon: coupon)
            sizingCell.configure(with: viewModel)
            sizingCell.layoutIfNeeded()
            var fittingSize = UIView.layoutFittingCompressedSize
            fittingSize.width = cellWidth
            let size = sizingCell.contentView.systemLayoutSizeFitting(fittingSize,
                                                                      withHorizontalFittingPriority: .required,
                                                                      verticalFittingPriority: .defaultLow)

            height = max(height, size.height)
        }
        return height
    }
}

// MARK: - collectionView
extension CouponsViewController {
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        coupons.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "couponCell", for: indexPath) as! CouponCollectionViewCell

        let viewModel = CouponViewModel(coupon: coupons[indexPath.row])
        cell.configure(with: viewModel)

        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let coupon = coupons[indexPath.row]
        delegate?.couponSelected(coupon)
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
