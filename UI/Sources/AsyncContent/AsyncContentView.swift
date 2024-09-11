//
//  AsyncContentView.swift
//  AutoLayout-Helper
//
//  Created by Andreas Osberghaus on 08.09.22.
//

import Foundation
import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

enum LoadingState<Value> {
    case idle
    case loading
    case failed(Error)
    case loaded(Value)
    case empty
}

struct AsyncContentView<Source: LoadableObject, Content: View, Empty: View, ErrorView: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    var empty: (() -> Empty)?
    var errorView: ((_ error: Error) -> ErrorView)?

    init(source: Source, content: @escaping (Source.Output) -> Content) where Empty == EmptyView, ErrorView == EmptyView {
        self.source = source
        self.content = content
        self.empty = nil
        self.errorView = nil
    }

    init(source: Source, content: @escaping (Source.Output) -> Content, empty: @escaping () -> Empty) where ErrorView == EmptyView {
        self.source = source
        self.content = content
        self.empty = empty
        self.errorView = nil
    }
    init(source: Source, content: @escaping (Source.Output) -> Content, empty: @escaping () -> Empty, errorView: @escaping (Error) -> ErrorView) {
        self.source = source
        self.content = content
        self.empty = empty
        self.errorView = errorView
    }

    var isLoading: Bool {
        if case .loading = source.state {
            return true
        }
        return false
    }

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading:
            ProgressView()
        case .failed(let error):
            if let errorView {
                errorView(error)
            } else {
                VStack(spacing: 16) {
                    Text(Asset.localizedString(forKey: "Snabble.Error.defaultMessage"))
                        .multilineTextAlignment(.center)
                    SecondaryButtonView(title: Asset.localizedString(forKey: "Snabble.Error.retry")) {                            self.source.load()
                    }
                }
                .padding()
            }
        case .empty:
            if let empty {
                empty()
            } else {
                EmptyView()
            }
        case .loaded(let output):
            content(output)
        }
    }
}
