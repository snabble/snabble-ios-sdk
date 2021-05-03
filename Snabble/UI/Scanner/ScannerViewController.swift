//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Pulley

public final class ScannerViewController: UIViewController {

    public init(_ cart: ShoppingCart, _ shop: Shop, _ detector: BarcodeDetector? = nil, delegate: ScannerDelegate) {
        super.init(nibName: nil, bundle: nil)

        self.title = "Snabble.Scanner.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("SnabbleSDK/icon-scan-inactive")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-scan-active")

        let scanningVC = ScanningViewController(cart, shop, detector, delegate: delegate)
        let drawerVC = DrawerViewController()

        let pulleyVC = PulleyViewController(contentViewController: scanningVC, drawerViewController: drawerVC)
        pulleyVC.delegate = self

        view.addSubview(pulleyVC.view)
        addChild(pulleyVC)
        pulleyVC.didMove(toParent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScannerViewController: PulleyDelegate {
    public func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        print(#function)
    }
}

// MARK: - dummy drawer

final class DrawerViewController: UIViewController {
    private var pulleyPositions = [PulleyPosition.closed]
    private var shoppingList: ShoppingList?

    private var tableView: UITableView!

    init() {
        super.init(nibName: nil, bundle: nil)

        view.translatesAutoresizingMaskIntoConstraints = false

        let shoppingLists = ShoppingList.fetchListsFromDisk()
        if let list = shoppingLists.first(where: {$0.projectId == SnabbleUI.project.id }), !list.isEmpty {
            self.shoppingList = list
            self.pulleyPositions = [.collapsed, .partiallyRevealed, .open]
        }

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0) // compensate for pulley's 20dp overshoot

        let handle = UIView()
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.layer.cornerRadius = 2
        handle.layer.masksToBounds = true
        handle.backgroundColor = .systemGray

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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("drawer will appear")
    }
}

extension DrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        self.pulleyPositions
    }
}

extension DrawerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")

        if let item = shoppingList?.itemAt(indexPath.row) {
            switch item.entry {
            case .custom(let text):
                cell.textLabel?.text = text
            case .product(let product):
                cell.textLabel?.text = product.name
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("toggle done/todo")
    }
}
