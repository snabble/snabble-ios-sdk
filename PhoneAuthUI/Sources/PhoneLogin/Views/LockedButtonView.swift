//
//  LockedActionButton.swift
//  teo
//
//  Created by Uwe Tilemann on 08.02.24.
//

import SwiftUI

/// Usage::
///
/// ```
/// struct ContentView: View {
///    @State var isEnabled = false
///
///    var body: some View {
///        LockedActionButton(title: "Button", action: {
///                // your action here
///        })
///        .disabled(!isEnabled)
///    }
/// }
///
struct LockedButtonView: View {
    let title: String
    let action: () -> Void
    
    var waitingInterval: TimeInterval = 30 // 30 seconds

    @State var isEnabled: Bool = false

    var body: some View {
        Button(action: {
            action()
            self.isEnabled = false
        }) {
            HStack {
                Text(title)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)
        .buttonStyle(LockedButtonStyle(interval: waitingInterval, isEnabled: $isEnabled))
    }
}

private struct LockedButtonStyle: ButtonStyle {
    var interval: TimeInterval
    @Binding var isEnabled: Bool
    
    @ViewBuilder
    var background: some View {
        if !isEnabled {
            CountDownButtonBackground(interval: interval) {
                DispatchQueue.main.async {
                    self.isEnabled = true
                }
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 10)
            .background(background)
            .foregroundColor(Color("AccentColor").opacity(!isEnabled ? 0.5 : 1.0))
            .disabled(!isEnabled)
            .clipShape(Capsule())
    }
}

private struct CountDownButtonBackground: View {
    let from: Date
    let to: Date
    let completion: () -> Void
    
    init(interval: Double, from: Date = .now, to: Date? = nil, completion: @escaping (() -> Void) = {}) {
        self.from = from
        self.to = to ?? (from + interval)
        self.completion = completion
    }

    var body: some View {
        TimelineView(.periodic(from: self.from, by: 1 / 20)) { timeContext in
            Canvas { context, size in
                let interval = to.timeIntervalSinceReferenceDate - from.timeIntervalSinceReferenceDate
                let width = size.width / interval * to.timeIntervalSinceNow
                
                if timeContext.date > self.to {
                    DispatchQueue.main.async {
                        self.completion()
                    }
                }
                
                let fdRect = Rectangle().path(in: CGRect(x: 0, y: 0, width: width, height: size.height))
                context.fill(fdRect, with: .color(Color.secondary.opacity(0.5)))
            }
        }
    }
}
