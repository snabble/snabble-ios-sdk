//
//  TeaserViewController.swift
//  teo
//
//  Created by Uwe Tilemann on 08.07.25.
//

import Combine
import SwiftUI

import SnabbleCore

public final class TeaserViewController: UIHostingController<TeaserView> {
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        super.init(rootView: TeaserView(model: TeaserModel()))
    }
    
    public var model: TeaserModel {
        rootView.model
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.zPosition = 1

        rootView.onNavigationPublisher.sink { [weak self] (teaser, image) in
            self?.displayDetails(teaser: teaser, image: image)
        }
        .store(in: &cancellables)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.invalidateIntrinsicContentSize()
    }

    private func displayDetails(teaser: CustomizationConfig.Teaser, image: UIImage?) {
        navigationController?.pushViewController(
            TeaserDetailController(model: model, teaser: teaser, image: image),
            animated: true
        )
    }
}
