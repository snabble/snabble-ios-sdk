//
//  ProfileView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 02.09.22.
//

import SwiftUI

public struct ProfileView: View {
    @ObservedObject public var viewModel: DynamicStackViewModel

    public var body: some View {
        NavigationView {
            WidgetContainer(viewModel: viewModel, widgets: viewModel.widgets)
                .navigationBarTitle(Asset.localizedString(forKey: "Snabble.DynamicList.title"), displayMode: .inline)
        }
        .navigationViewStyle(.stack)
   }
}
