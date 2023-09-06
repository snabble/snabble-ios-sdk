//
//  ReceiptCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

class ReceiptContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            if let configuration = configuration as? ReceiptContentConfiguration {
                imageView?.image = configuration.image
                titleLabel?.text = configuration.title
                subtitleLabel?.text = configuration.subtitle
                disclosureLabel?.text = configuration.disclosure

                if configuration.showProjectImage {
                    configuration.icon { [weak self] in
                        self?.imageView?.image = $0
                    }
                }

            } else {
                imageView?.image = nil
                titleLabel?.text = nil
                subtitleLabel?.text = nil
                disclosureLabel?.text = nil
            }
        }
    }

    func supports(_ configuration: UIContentConfiguration) -> Bool {
       configuration is ReceiptContentConfiguration
    }

    private(set) weak var imageView: UIImageView?
    private(set) weak var titleLabel: UILabel?
    private(set) weak var subtitleLabel: UILabel?
    private(set) weak var disclosureLabel: UILabel?

    init(configuration: ReceiptContentConfiguration) {
        self.configuration = configuration

        let imageView = UIImageView(image: configuration.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = configuration.title
        titleLabel.numberOfLines = 2
        titleLabel.font = .preferredFont(forTextStyle: .body, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = configuration.subtitle
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = .preferredFont(forTextStyle: .caption2)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)

        let disclosureLabel = UILabel()
        disclosureLabel.translatesAutoresizingMaskIntoConstraints = false
        disclosureLabel.text = configuration.disclosure
        disclosureLabel.numberOfLines = 1
        disclosureLabel.font = .preferredFont(forTextStyle: .caption1)
        disclosureLabel.adjustsFontForContentSizeCategory = true
        disclosureLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        super.init(frame: .zero)

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(disclosureLabel)

        self.imageView = imageView
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.disclosureLabel = disclosureLabel

        let centerLayoutGuide = UILayoutGuide()
        addLayoutGuide(centerLayoutGuide)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44).usingPriority(.defaultLow - 1),

            imageView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            centerLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 2),
            disclosureLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: centerLayoutGuide.trailingAnchor, multiplier: 1),
            trailingAnchor.constraint(equalToSystemSpacingAfter: disclosureLabel.trailingAnchor, multiplier: 1),

            imageView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 2),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            centerLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.5),
            bottomAnchor.constraint(equalToSystemSpacingBelow: centerLayoutGuide.bottomAnchor, multiplier: 1.5),
            centerLayoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor),

            disclosureLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: disclosureLabel.bottomAnchor, multiplier: 2),
            disclosureLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: centerLayoutGuide.leadingAnchor),
            centerLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: centerLayoutGuide.leadingAnchor),
            centerLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.trailingAnchor),

            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: centerLayoutGuide.topAnchor),
            subtitleLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 0.5),
            centerLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ReceiptContentConfiguration: UIContentConfiguration {
    var image: UIImage? {
        UIImage(systemName: "scroll")
    }
    let title: String
    let subtitle: String?
    let disclosure: String?

    var showProjectImage: Bool = true

    private let order: Order

    init(order: Order) {
        self.order = order
        title = order.shopName

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        subtitle = dateFormatter.string(for: order.date)

        if let project = Snabble.shared.project(for: order.projectId) {
            let formatter = PriceFormatter(project)
            disclosure = formatter.format(order.price)
        } else {
            let formatter = PriceFormatter(2, "de_DE", "EUR", "€")
            disclosure = formatter.format(order.price)
        }
    }

    var accessoryType: UITableViewCell.AccessoryType {
        guard disclosure != nil else {
            return .none
        }
        return .disclosureIndicator
    }

    func makeContentView() -> UIView & UIContentView {
        ReceiptContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        self
    }

    func icon(completion: @escaping (UIImage?) -> Void) {
        SnabbleCI.getAsset(.storeIcon, projectId: order.projectId) { image in
            completion(image)
        }
    }
}

//final class ReceiptCell: UITableViewCell {
//    private let storeIcon = UIImageView()
//    private let storeName = UILabel()
//    private let orderDate = UILabel()
//    private let price = UILabel()
//
//    private var projectId: Identifier<Project>?
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        accessoryType = .disclosureIndicator
//
//        storeIcon.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(storeIcon)
//
//        storeName.translatesAutoresizingMaskIntoConstraints = false
//        storeName.numberOfLines = 0
//        storeName.font = .preferredFont(forTextStyle: .body)
//        storeName.adjustsFontForContentSizeCategory = true
//        contentView.addSubview(storeName)
//
//        orderDate.translatesAutoresizingMaskIntoConstraints = false
//        orderDate.numberOfLines = 0
//        orderDate.textColor = .secondaryLabel
//        orderDate.font = .preferredFont(forTextStyle: .footnote)
//        orderDate.adjustsFontForContentSizeCategory = true
//        contentView.addSubview(orderDate)
//
//        price.translatesAutoresizingMaskIntoConstraints = false
//        price.textColor = .secondaryLabel
//        price.font = .preferredFont(forTextStyle: .footnote)
//        price.adjustsFontForContentSizeCategory = true
//        price.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        price.setContentCompressionResistancePriority(.required, for: .horizontal)
//        contentView.addSubview(price)
//
//        NSLayoutConstraint.activate([
//            storeIcon.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 0),
//            storeIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            storeIcon.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0),
//            storeIcon.widthAnchor.constraint(equalToConstant: 24),
//
//            storeIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            storeIcon.heightAnchor.constraint(equalTo: storeIcon.widthAnchor),
//
//            storeName.leadingAnchor.constraint(equalTo: storeIcon.trailingAnchor, constant: 16),
//            storeName.trailingAnchor.constraint(equalTo: price.leadingAnchor, constant: -16),
//            storeName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//
//            orderDate.leadingAnchor.constraint(equalTo: storeName.leadingAnchor),
//            orderDate.trailingAnchor.constraint(equalTo: price.leadingAnchor, constant: -16),
//            orderDate.topAnchor.constraint(equalTo: storeName.bottomAnchor, constant: 8),
//            orderDate.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
//
//            price.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
//            price.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//
//        self.storeIcon.image = nil
//        self.storeName.text = nil
//        self.orderDate.text = nil
//        self.price.text = nil
//
//        self.projectId = nil
//    }
//
//    func show(_ orderEntry: OrderEntry) {
//        switch orderEntry {
//        case .done(let order):
//            if let project = Snabble.shared.project(for: order.projectId) {
//                let formatter = PriceFormatter(project)
//                self.price.text = formatter.format(order.price)
//            } else {
//                let formatter = PriceFormatter(2, "de_DE", "EUR", "€")
//                self.price.text = formatter.format(order.price)
//            }
//
//            self.storeName.text = order.shopName
//
//            self.showIcon(order.projectId)
//
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .medium
//            dateFormatter.timeStyle = .short
//            let date = dateFormatter.string(from: order.date)
//            self.orderDate.text = date
//
//        case .pending(let shopName, let projectId):
//            self.storeName.text = shopName
//            self.showIcon(projectId)
//            self.orderDate.text = Asset.localizedString(forKey: "Snabble.Receipts.loading")
//            let spinner = UIActivityIndicatorView(style: .medium)
//            spinner.color = .systemGray
//            spinner.startAnimating()
//            self.accessoryView = spinner
//            self.price.text = ""
//        }
//    }
//
//    private func showIcon(_ projectId: Identifier<Project>) {
//        self.projectId = projectId
//
//        SnabbleCI.getAsset(.storeIcon, projectId: projectId) { [weak self] img in
//            if let img = img, self?.projectId == projectId {
//                self?.storeIcon.image = img
//            } else {
//                self?.storeIcon.image = UIImage(named: projectId.rawValue)
//            }
//        }
//    }
//}
