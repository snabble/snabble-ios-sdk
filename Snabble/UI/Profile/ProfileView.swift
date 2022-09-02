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
        DynamicStackView(viewModel: viewModel)
    }
}
