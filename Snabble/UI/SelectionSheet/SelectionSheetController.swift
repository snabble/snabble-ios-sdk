//
//  SelectionSheetController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import AutoLayout_Helper

final class SelectionSheetController: UIViewController {
    private let cancelButton = UIButton(type: .custom)
    private let selectionView = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let tableView = SelectionSheetTableView()

    private var cancelButtonBottom: NSLayoutConstraint?
    private var selectionViewTop: NSLayoutConstraint?

    var message: String?
    var appearance: SelectionSheetAppearance = DefaultSelectionSheetAppearance()

    private(set) var actions = [SelectionSheetAction]()

    var cancelButtonTitle: String? {
        didSet { cancelButton.setTitle(cancelButtonTitle, for: .normal) }
    }

    var cancelHandler: (() -> Void)?

    init(title: String? = nil, message: String? = nil) {
        self.message = message

        super.init(nibName: nil, bundle: nil)

        self.title = title

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let presentationController = navigationController?.presentationController ?? presentationController
        presentationController?.delegate = self

        let dimmingBackground = UIView()
        dimmingBackground.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped(_:)))
        dimmingBackground.addGestureRecognizer(tap)
        dimmingBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingBackground)

        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.backgroundColor = appearance.backgroundColor
        selectionView.layer.cornerRadius = 8
        selectionView.layer.masksToBounds = true
        view.addSubview(selectionView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        let showHeader = title != nil || message != nil
        let margins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stackView.directionalLayoutMargins = showHeader ? margins : .zero
        stackView.spacing = 8

        let title = UILabel()
        title.numberOfLines = 0
        title.text = self.title
        title.font = appearance.titleFont
        title.textColor = appearance.titleColor
        title.isHidden = self.title == nil
        title.textAlignment = .center
        stackView.addArrangedSubview(title)

        let message = UILabel()
        message.text = self.message
        message.numberOfLines = 0
        message.font = appearance.messageFont
        message.textColor = appearance.messageColor
        message.isHidden = self.message == nil
        message.textAlignment = .center
        stackView.addArrangedSubview(message)
        scrollView.addSubview(stackView)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .separator
        selectionView.addSubview(separator)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(SelectionSheetTableCell.self, forCellReuseIdentifier: "cell")
        tableView.setContentCompressionResistancePriority(.defaultHigh - 1, for: .vertical)
        tableView.setContentHuggingPriority(.required, for: .vertical)
        tableView.alwaysBounceVertical = false
        tableView.separatorInset = .zero
        selectionView.addSubview(tableView)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.layer.cornerRadius = 8
        cancelButton.backgroundColor = appearance.backgroundColor
        cancelButton.titleLabel?.font = appearance.cancelButtonFont
        cancelButton.setTitleColor(appearance.cancelButtonColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(self.cancelTapped(_:)), for: .touchUpInside)
        view.addSubview(cancelButton)

        let safeArea = view.safeAreaLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            dimmingBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingBackground.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 57),

            selectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            selectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            selectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            selectionView.topAnchor.constraint(greaterThanOrEqualTo: safeArea.topAnchor, constant: 16),

            // initial setup: push everything off-screen
            selectionView.topAnchor.constraint(equalTo: view.bottomAnchor)
                .usingVariable(&selectionViewTop),

            tableView.leadingAnchor.constraint(equalTo: selectionView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: selectionView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor),

            separator.leadingAnchor.constraint(equalTo: selectionView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: selectionView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            scrollView.leadingAnchor.constraint(equalTo: selectionView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: selectionView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: selectionView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: 0),
            contentGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            scrollView.heightAnchor.constraint(lessThanOrEqualTo: selectionView.heightAnchor, multiplier: 0.5)
                .usingPriority(.defaultHigh - 2),
            scrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor)
                .usingPriority(.defaultHigh - 1),

            stackView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // avoid UITableView layout warnings
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.15) {
                // deactivate initial push-down constraint
                self.selectionViewTop?.isActive = false
                let viewBottom = self.view.safeAreaLayoutGuide.bottomAnchor
                self.cancelButtonBottom = self.cancelButton.bottomAnchor.constraint(equalTo: viewBottom, constant: -16)
                self.cancelButtonBottom?.isActive = true
                self.view.layoutIfNeeded()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollView.flashScrollIndicators()
        tableView.flashScrollIndicators()
    }

    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // animate the selection view back down off-screen
        UIView.animate(withDuration: 0.15) {
            self.cancelButtonBottom?.isActive = false
            self.selectionViewTop?.isActive = true
            self.view.layoutIfNeeded()
        }

        super.dismiss(animated: animated, completion: completion)
    }

    func addAction(_ action: SelectionSheetAction) {
        actions.append(action)
    }

    @objc private func cancelTapped(_ sender: Any) {
        cancelHandler?()
        dismiss(animated: true)
    }
}

extension SelectionSheetController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SelectionSheetTableCell
        cell.configure(with: actions[indexPath.row], appearance: appearance)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let action = actions[indexPath.row]
        action.handler?(action)
        dismiss(animated: true)
    }
}

extension SelectionSheetController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        cancelHandler?()
        dismiss(animated: true)
    }
}
