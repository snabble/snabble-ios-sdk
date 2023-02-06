//
//  CheckoutInformationTableViewCell.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//
#if !SWIFTUI_PROFILE
import Foundation
import UIKit

final class CheckoutInformationTableViewCell: UITableViewCell, ReuseIdentifiable {
    private(set) weak var informationView: CheckoutInformationView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let informationView = CheckoutInformationView()
        informationView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(informationView)

        self.informationView = informationView

        NSLayoutConstraint.activate([
            informationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: informationView.trailingAnchor),
            informationView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: informationView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
