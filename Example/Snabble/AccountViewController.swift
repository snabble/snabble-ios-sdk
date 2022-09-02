//
//  AccountViewController.swift
//  SnabbleSampleApp
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK
import SwiftUI

public struct ProfileView: View {
    @ObservedObject public var viewModel: DynamicViewModel

    public var body: some View {
        NavigationView {
            WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                .navigationBarTitle(Asset.localizedString(forKey: "Sample.Profile.title"), displayMode: .inline)
        }
        .navigationViewStyle(.stack)
   }
}

final class AccountViewController: SnabbleSDK.DynamicViewController {

    override init(viewModel: DynamicViewModel) {
        super.init(viewModel: viewModel)

        title = NSLocalizedString("Sample.account", comment: "")
        tabBarItem.image = UIImage(named: "Navigation/TabBar/profil-off")
        tabBarItem.selectedImage = UIImage(named: "Navigation/TabBar/profil-off")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
