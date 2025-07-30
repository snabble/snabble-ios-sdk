//
//  TeaserView.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

import Combine

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

extension CustomizationConfig.Teaser: Hashable {
    public static func == (lhs: CustomizationConfig.Teaser, rhs: CustomizationConfig.Teaser) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct TeaserView: View {
    @State public var model: TeaserModel
    @State public var activePage: CustomizationConfig.Teaser?

    public let onNavigationPublisher: PassthroughSubject<(teaser: CustomizationConfig.Teaser, image: UIImage?), Never>

    public init(
        model: TeaserModel,
        activePage: CustomizationConfig.Teaser? = nil,
        actionPublisher: PassthroughSubject<(teaser: CustomizationConfig.Teaser, image: UIImage?), Never> = .init()) {
        self.model = model
        self.activePage = activePage
        self.onNavigationPublisher = actionPublisher
    }

    public var body: some View {
        VStack {
            VStack(spacing: 18) {
                Text(Asset.localizedString(forKey: "Snabble.Teaser.title"))
                    .font(.font("SnabbleUI.CustomFont.header", size: 20, relativeTo: .body, domain: nil))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.projectPrimary())
                    .padding(.leading, 7)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(model.teasers, id: \.self) { teaser in
                            TeaserItemView(teaser: teaser) { image in
                                onNavigationPublisher.send((teaser, image))
                            }
                            .environment(model)
                            .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 1))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.systemBackground)
                            )
                        }
                        .padding(.horizontal, 25)
                        .frame(height: 210)
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                    }
                    .scrollTargetLayout()
                }
                .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $activePage)
                .scrollIndicators(.never)

                pagingControl
                    .opacity(model.teasers.count > 1 ? 1 : 0)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .background(Color.projectFaq())
        .font(.font("SnabbleUI.CustomFont.teaser", size: 17, relativeTo: .body, domain: nil))
    }
    
    @ViewBuilder
    var pagingControl: some View {
        HStack {
            ForEach(model.teasers) { page in
                Button {
                    withAnimation {
                        activePage = page
                    }
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(activePage == page ? Color.projectPrimary() : .white)
                }
            }
        }
        .task {
            if activePage == nil {
                activePage = model.teasers.first
            }
        }
    }

}
