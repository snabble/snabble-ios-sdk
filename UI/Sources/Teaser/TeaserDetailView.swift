//
//  TeaserDetailView.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import UIKit
import SwiftUI
import WebKit

import SnabbleCore
import SnabbleComponents
import SnabbleAssetProviding

extension String {
    var extractYouTubeID: String? {
        guard let url = URL(string: self),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first(where: { $0.name == "v" })?.value
    }
}
struct YouTubeView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
        </head>
        <body>
            <iframe width="100%" height="100%" src="https://www.youtube.com/embed/\(videoID)?playsinline=1" frameborder="0" allowfullscreen></iframe>
        </body>
        </html>
        """
        uiView.loadHTMLString(embedHTML, baseURL: nil)
    }
}

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
    
    @ViewBuilder
    var imageView: some View {
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
    }

    @ViewBuilder
    var videoView: some View {
        HStack {
            if let videoURL = teaser.videoUrl, let videoID = videoURL.extractYouTubeID {
                YouTubeView(videoID: videoID)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: image)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {

                if teaser.videoUrl != nil {
                    videoView
                } else {
                    imageView
                }
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

            if let videoUrl = teaser.videoUrl {
                
            } else if let urlString = teaser.detailImageUrl {
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
