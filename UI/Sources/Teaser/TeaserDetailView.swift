//
//  TeaserDetailView.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import UIKit
import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleAssetProviding

public struct TeaserDetailView: View {
    @Environment(\.openURL) var openURL

    public let model: TeaserModel
    public let teaser: CustomizationConfig.Teaser
    public let initialImage: UIImage?

    @State private var image: UIImage?
    
    @State private var isLoading: Bool = false
    
    public init(model: TeaserModel, teaser: CustomizationConfig.Teaser, image: UIImage?) {
        self.model = model
        self.teaser = teaser
        self.initialImage = image
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack {
                    if let displayImage = image ?? initialImage {
                        SwiftUI.Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .overlay(
                                ProgressView()
                                    .opacity(isLoading ? 1.0 : 0.0)
                            )
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.default, value: image)

                VStack(alignment: .leading, spacing: 16) {
                    Text(!teaser.localizedDetailTitle.isEmpty ? teaser.localizedDetailTitle : teaser.localizedTitle)
                        .font(.font("SnabbleUI.CustomFont.header", size: 20, relativeTo: .body, domain: nil))
                        .fontWeight(.bold)
                    
                    Text(!teaser.localizedDetailSubtitle.isEmpty ? teaser.localizedDetailSubtitle : teaser.localizedSubtitle)
                    
                    if let urlString = teaser.url, let url = URL(string: urlString) {
                        Button(action: {
                            openURL(url)
                        }) {
                            Text(Asset.localizedString(forKey: "Snabble.Teaser.moreButtonTitle"))
                                .font(.subheadline)
                                .foregroundColor(Color.projectPrimary())
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ProjectBorderedPrimaryButtonStyle())
                        .padding(.horizontal, 64)
                        .padding(.top, 16)
                    }
                    
                }
                .padding(.horizontal, 25)

                Spacer()
            }
        }
        .task {
            if image == nil {
                image = initialImage
            }

            if let urlString = teaser.detailImageUrl {
                await loadImage(urlString)
            } else {
                if image == nil, let urlString = teaser.imageUrl {
                    await loadImage(urlString)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .font(.font("SnabbleUI.CustomFont.teaser", size: 17, relativeTo: .body, domain: nil))
        .navigationTitle(Asset.localizedString(forKey: "Snabble.Teaser.title"))
    }
    
    @MainActor
    private func loadImage(_ urlString: String?) async {
        guard let imageUrl = urlString else { return }
        
        isLoading = true
        image = await model.loadImage(from: imageUrl)
        isLoading = false
    }
}
