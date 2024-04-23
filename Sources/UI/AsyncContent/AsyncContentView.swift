//
//  AsyncContentView.swift
//  AutoLayout-Helper
//
//  Created by Andreas Osberghaus on 08.09.22.
//

import Foundation
import SwiftUI

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

struct AsyncContentView<Source: LoadableObject, Content: View, Empty: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    var empty: (() -> Empty)?

    init(source: Source, content: @escaping (Source.Output) -> Content) where Empty == EmptyView {
        self.source = source
        self.content = content
        self.empty = nil
    }

    init(source: Source, content: @escaping (Source.Output) -> Content, empty: @escaping () -> Empty) {
        self.source = source
        self.content = content
        self.empty = empty
    }

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading:
            ProgressView()
        case .failed:
            ErrorView()
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

struct ErrorView: View {
    var body: some View {
        Text("Error")
    }
}
