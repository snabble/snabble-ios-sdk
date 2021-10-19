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

    private(set) weak var scrollView: UIScrollView?

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

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.isDirectionalLockEnabled = true
        view.addSubview(scrollView)
        self.scrollView = scrollView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
        ])

        let headerView = CheckoutHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(headerView)
        self.headerView = headerView

        let cardView = CardView()
        cardView.translatesAutoresizingMaskIntoConstraints = false

        let stepsStackView = UIStackView()
        stepsStackView.backgroundColor = .red
        stepsStackView.translatesAutoresizingMaskIntoConstraints = false
        stepsStackView.axis = .vertical
        stepsStackView.distribution = .fill
        stepsStackView.alignment = .fill
        cardView.contentView.addSubview(stepsStackView)
        self.stepsStackView = stepsStackView

        scrollView.addSubview(cardView)

        let ratingView = CheckoutRatingView()
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(ratingView)
        self.ratingView = ratingView

        let doneButton = UIButton(type: .system)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Schließen", for: .normal)
        doneButton.makeSnabbleButton()
        scrollView.addSubview(doneButton)
        self.doneButton = doneButton

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),

            headerView.widthAnchor.constraint(equalTo: headerView.heightAnchor, multiplier: 1.75),

            cardView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 16),

            stepsStackView.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor),
            stepsStackView.topAnchor.constraint(equalTo: cardView.contentView.topAnchor),
            cardView.contentView.trailingAnchor.constraint(equalTo: stepsStackView.trailingAnchor),
            cardView.contentView.bottomAnchor.constraint(equalTo: stepsStackView.bottomAnchor),

            doneButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: doneButton.trailingAnchor, constant: 24),

            doneButton.heightAnchor.constraint(equalToConstant: 48),

            ratingView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(greaterThanOrEqualTo: ratingView.trailingAnchor, constant: 16),
            ratingView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            headerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            ratingView.topAnchor.constraint(greaterThanOrEqualTo: cardView.bottomAnchor, constant: 16),
            ratingView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16).usingPriority(.defaultLow - 1),
            doneButton.topAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: 16),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 16)
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

private extension UIStackView {
    func addHorizontalSeparators(color: UIColor) {
        var index = arrangedSubviews.count - 1
        while index > 0 {
            let separator = UIView()
            separator.backgroundColor = color
            insertArrangedSubview(separator, at: index)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
                separator.widthAnchor.constraint(equalTo: widthAnchor)
            ])
            index -= 1
        }
    }
}

private class CardView: UIView {
    private(set) var contentView: UIView

    var cornerRadius: CGFloat = 8
    var shadowColor: UIColor? = .black
    var shadowOpacity: Float = 0.25
    var shadowOffset: CGSize = .init(width: 0, height: 3)

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

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false

        layer.shadowColor = shadowColor?.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath

        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true
    }
}
