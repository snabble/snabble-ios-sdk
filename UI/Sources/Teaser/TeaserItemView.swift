//
//  TeaserItemView.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import SwiftUI

import SnabbleCore

public struct TeaserItemView: View {
    @Environment(TeaserModel.self) var model
    public let teaser: CustomizationConfig.Teaser
    public let action: (_ action: UIImage?) -> Void
    
    @State private var isLoading = false
    @State private var image: UIImage?

    @ViewBuilder
    var imageView: some View {
        GeometryReader { geometry in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 124)
                        .clipped()
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            ProgressView()
                        )
                }
            }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageView
                .frame(height: 124)

            VStack(alignment: .leading, spacing: 0) {
                Text(teaser.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .padding(.bottom, 4)
                Text(teaser.localizedSubtitle)
                    .font(.footnote)
                    .lineLimit(2)
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action(image)
        }
        .task {
            await loadImage()
        }
    }
    
    @MainActor
    private func loadImage() async {
        guard let imageUrl = teaser.imageUrl else { return }

        isLoading = true
        image = await model.loadImage(from: imageUrl)
        isLoading = false
    }
}
