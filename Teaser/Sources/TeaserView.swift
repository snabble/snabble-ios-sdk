//
//  TeaserView.swift
//  teo
//
//  Created by Uwe Tilemann on 09.07.25.
//

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
    let model: TeaserModel
    @State public var activePage: CustomizationConfig.Teaser?

    public var onNavigation: ((CustomizationConfig.Teaser, UIImage?) -> Void)?

    public init(
        model: TeaserModel,
        activePage: CustomizationConfig.Teaser? = nil,
        onNavigation: ((CustomizationConfig.Teaser, UIImage?) -> Void)? = nil) {
        self.model = model
        self.activePage = activePage
        self.onNavigation = onNavigation
    }

    public var body: some View {
        if !model.teasers.isEmpty {
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
                                    onNavigation?(teaser, image)
                                }
                                .environment(model)
                                .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 1))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.systemBackground)
                                )
                            }
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $activePage)
                    .scrollIndicators(.never)
                    
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
                    .opacity(model.teasers.count > 1 ? 1 : 0)
                    .task {
                        if activePage == nil {
                            activePage = model.teasers.first
                        }
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .background(Color.projectFaq())
            .font(.font("SnabbleUI.CustomFont.teaser", size: 17, relativeTo: .body, domain: nil))
        }
    }
}
