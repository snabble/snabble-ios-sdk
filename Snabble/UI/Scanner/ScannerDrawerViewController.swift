//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

final class ScannerDrawerViewController: UIViewController {
    private var pulleyPositions = [PulleyPosition]()
    private var shoppingList: ShoppingList?
    private let projectId: Identifier<Project>
    private var tableView = UITableView()
    private weak var delegate: AnalyticsDelegate?

    init(_ projectId: Identifier<Project>, delegate: AnalyticsDelegate) {
        self.projectId = projectId
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        let handle = UIView()
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.layer.cornerRadius = 2
        handle.layer.masksToBounds = true
        handle.backgroundColor = .systemGray
        handle.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        handle.addGestureRecognizer(tap)

        let tableWrapper = UIView()
        tableWrapper.translatesAutoresizingMaskIntoConstraints = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        let nib = UINib(nibName: "ShoppingListCell", bundle: SnabbleBundle.main)
        tableView.register(nib, forCellReuseIdentifier: "shoppingListCell")
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0) // 20pt overshoot from Pulley
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets

        view.backgroundColor = .systemBackground
        view.addSubview(handle)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            handle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handle.heightAnchor.constraint(equalToConstant: 4),
            handle.widthAnchor.constraint(equalToConstant: 60),

            tableView.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let shoppingLists = ShoppingList.fetchListsFromDisk()
        if let list = shoppingLists.first(where: {$0.projectId == projectId}), !list.isEmpty {
            self.shoppingList = list
            self.pulleyPositions = [.collapsed, .partiallyRevealed, .open]
            if self.pulleyViewController?.drawerPosition == .closed {
                self.pulleyViewController?.setDrawerPosition(position: .collapsed, animated: true)
            }
        } else {
            self.shoppingList = nil
            self.pulleyPositions = [.closed]
            self.pulleyViewController?.setDrawerPosition(position: .closed, animated: false)
        }

        self.pulleyViewController?.setNeedsSupportedDrawerPositionsUpdate()
        self.tableView.reloadData()
    }

    @objc private func handleTapped(_ gesture: UITapGestureRecognizer) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }
}

// MARK: - TableView
extension ScannerDrawerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as! ShoppingListCell

        let item = shoppingList!.itemAt(indexPath.row)
        cell.setListItem(item)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let checked = shoppingList!.toggleChecked(at: indexPath.row)
        delegate?.track(checked ? .itemMarkedDone : .itemMarkedTodo)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - pulley
extension ScannerDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        tableView.isScrollEnabled = drawer.drawerPosition == .open
    }
}
