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

struct AsyncContentView<Source: LoadableObject, Content: View, PlaceholderContent: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    var placeholder: (() -> PlaceholderContent)?
    
    init(source: Source, content: @escaping (Source.Output) -> Content) where PlaceholderContent == EmptyView {
        self.source = source
        self.content = content
        self.placeholder = nil
    }
    init(source: Source, content: @escaping (Source.Output) -> Content, placeholder: @escaping () -> PlaceholderContent) {
        self.source = source
        self.content = content
        self.placeholder = placeholder
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
            if let placeholder {
                placeholder()
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
