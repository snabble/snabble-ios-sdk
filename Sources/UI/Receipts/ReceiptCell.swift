//
//  ReceiptCell.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

#if SWIFTUI_RECEIPT
// remove file
#else
class ReceiptContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            if let configuration = configuration as? ReceiptContentConfiguration {
                imageView?.image = configuration.image
                titleLabel?.text = configuration.title
                subtitleLabel?.text = configuration.subtitle
                disclosureLabel?.text = configuration.disclosure

                if configuration.showProjectImage {
                    configuration.storeImage { [weak self] in
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
    static let tableViewCellIdentifier = "receiptContentCellIdentifier"

    var image: UIImage? {
        UIImage(systemName: "scroll")
    }
    let title: String
    let subtitle: String
    let disclosure: String
    let unloaded: Bool

    var showProjectImage: Bool = true

    private let projectId: Identifier<Project>

    init(order: Order) {
        projectId = order.projectId
        title = order.shopName

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        subtitle = dateFormatter.string(for: order.date)!

        if let project = Snabble.shared.project(for: order.projectId) {
            let formatter = PriceFormatter(project)
            disclosure = formatter.format(order.price)
            unloaded = !order.hasCachedReceipt(project)
        } else {
            let formatter = PriceFormatter(2, "de_DE", "EUR", "€")
            disclosure = formatter.format(order.price)
            unloaded = true
       }
    }

    func makeContentView() -> UIView & UIContentView {
        ReceiptContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        self
    }

    func storeImage(completion: @escaping (UIImage?) -> Void) {
        SnabbleCI.getAsset(.storeIcon, projectId: projectId) { image in
            completion(image)
        }
    }
}
#endif
