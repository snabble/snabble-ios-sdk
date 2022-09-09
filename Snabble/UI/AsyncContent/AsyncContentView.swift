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

struct AsyncContentView<Source: LoadableObject, Content: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading, .failed, .empty:
            EmptyView()
        case .loaded(let output):
            content(output)
        }
    }
}
