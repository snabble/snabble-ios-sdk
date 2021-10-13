//
//  CheckoutStepsViewController.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.10.21.
//

import Foundation
import UIKit

public final class CheckoutStepsViewController: UIViewController {
    let viewModel: CheckoutStepsViewModel

    private(set) weak var headerView: CheckoutHeaderView?
    private(set) weak var stepsStackView: UIStackView?
    private(set) weak var ratingView: CheckoutRatingView?
    private(set) weak var doneButton: UIButton?

    public init() {
        viewModel = CheckoutStepsViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        let headerView = CheckoutHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        self.headerView = headerView

        let cardView = CardView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.enableCardStyle()

        let stepsStackView = UIStackView()
        stepsStackView.backgroundColor = .red
        stepsStackView.translatesAutoresizingMaskIntoConstraints = false
        stepsStackView.axis = .vertical
        stepsStackView.distribution = .fill
        stepsStackView.alignment = .fill
        cardView.contentView.addSubview(stepsStackView)
        self.stepsStackView = stepsStackView

        view.addSubview(cardView)

        let ratingView = CheckoutRatingView()
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ratingView)
        self.ratingView = ratingView

        let doneButton = UIButton(type: .system)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Schließen", for: .normal)
        doneButton.makeSnabbleButton()
        view.addSubview(doneButton)
        self.doneButton = doneButton

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),

            headerView.widthAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 1.75),

            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 16),

            stepsStackView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            stepsStackView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            cardView.contentView.trailingAnchor.constraint(equalTo: stepsStackView.trailingAnchor),
            cardView.contentView.bottomAnchor.constraint(equalTo: stepsStackView.bottomAnchor),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: doneButton.trailingAnchor, constant: 24),

            doneButton.heightAnchor.constraint(equalToConstant: 48),

            ratingView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: ratingView.trailingAnchor, constant: 16),
            ratingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),

            doneButton.topAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: 16),
            doneButton.topAnchor.constraint(greaterThanOrEqualTo: cardView.bottomAnchor, constant: 16),
            view.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 16)
        ])

        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        viewModel.steps
            .map { stepViewModel -> UIView in
                let view = CheckoutStepView()
                view.configure(with: stepViewModel)
                return view
            }
            .forEach { [weak self] stepView in
                self?.stepsStackView?.addArrangedSubview(stepView)
            }
        stepsStackView?.addHorizontalSeparators(color: .label)

        headerView?.configure(with: viewModel.headerViewModel)
    }
}

extension UIStackView {
    func addHorizontalSeparators(color : UIColor) {
        var i = arrangedSubviews.count - 1
        while i > 0 {
            let separator = createSeparator(color: color)
            insertArrangedSubview(separator, at: i)
            separator.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            i -= 1
        }
    }

    private func createSeparator(color : UIColor) -> UIView {
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        separator.backgroundColor = color
        return separator
    }
}

protocol Cardable: UIView {
    var contentView: UIView { get }
    func enableCardStyle()
}

class CardView: UIView, Cardable {
    private(set) var contentView: UIView

    override init(frame: CGRect) {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = contentView
        super.init(frame: frame)
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Cardable {
    func enableCardStyle() {
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .init(width: 0, height: 3)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.25

        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
    }
}
