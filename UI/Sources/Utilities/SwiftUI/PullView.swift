//
//  PullView.swift
//  PullViewSample
//
//  Created by Uwe Tilemann on 25.09.22.
//

import Foundation
import SwiftUI

struct PullOverView<Content>: View where Content: View {
    @Binding var minHeight: CGFloat
    let paddingTop: CGFloat
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let content: () -> Content

    init(minHeight: Binding<CGFloat>, paddingTop: CGFloat = 16, onExpand: @escaping () -> Void, onCollapse: @escaping () -> Void, content: @escaping () -> Content) {
        self._minHeight = minHeight
        self.paddingTop = paddingTop
        self.onExpand = onExpand
        self.onCollapse = onCollapse
        self.content = content
    }
    
    public var body: some View {
        ModifiedContent(content: self.content(), modifier: PullView(minHeight: $minHeight, paddingTop: paddingTop, onExpand: onExpand, onCollapse: onCollapse))
    }
}

struct CardShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let topRightStart = CGPoint(x: rect.maxX, y: rect.minY + radius)
        let topRightCenter = CGPoint(x: rect.maxX - radius, y: rect.minY + radius)
        let topLeftStart = CGPoint(x: rect.minX + radius, y: rect.minY)
        let topLeftCenter = CGPoint(x: rect.minX + radius, y: rect.minY + radius)
        
        path.move(to: bottomLeft)
        path.addLine(to: bottomRight)
        
        path.addLine(to: topRightStart)
        path.addRelativeArc(
            center: topRightCenter,
            radius: radius,
            startAngle: Angle.degrees(0),
            delta: Angle.degrees(-90))
        
        path.addLine(to: topLeftStart)
        path.addRelativeArc(
            center: topLeftCenter,
            radius: radius,
            startAngle: Angle.degrees(-90),
            delta: Angle.degrees(-90))
        
        return path
    }
}

struct ThickMaterial: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .background(.thickMaterial)
        } else {
            content
        }
    }
}

extension View {
    func thickMaterial() -> some View {
        modifier(ThickMaterial())
    }
}

struct PullView: ViewModifier {
    @Binding var minHeight: CGFloat
    let paddingTop: CGFloat
    let onExpand: () -> Void
    let onCollapse: () -> Void

    @State private var dragging = false
    @GestureState private var dragTracker = CGSize.zero
    @State private var position: CGFloat = 0
    @State private var minYPosition: CGFloat = 0
    
    func setupMinHeight(geom: GeometryProxy) {
        minYPosition = geom.size.height - minHeight
        position = minYPosition
    }
    func body(content: Content) -> some View {
        GeometryReader { geom in
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 60, height: 6.0)
                        .foregroundColor(.secondary)
                        .padding(10)
                    content.padding(.top, 16)
                }
                .frame(minWidth: UIScreen.main.bounds.width)
//                .scaleEffect(x: 1, y: 1, anchor: .center)
                .thickMaterial()
//                .clipShape( CardShape(radius: 16) )
            }
            .onChange(of: minHeight) {
                setupMinHeight(geom: geom)
            }
            .onAppear {
                setupMinHeight(geom: geom)
            }
            .frame(maxHeight: geom.size.height - (position + self.dragTracker.height /*- 10*/))
            .offset(y: max(0, position + self.dragTracker.height + 20))
            .animation(.easeInOut(duration: 0.2), value: position)
            .animation(Animation.interpolatingSpring(stiffness: 250.0, damping: 40.0, initialVelocity: 5.0), value: dragging)
            .gesture(
                DragGesture()
                    .updating($dragTracker) { drag, state, _ in
                        state = drag.translation
                    }
                    .onChanged {_ in
                        dragging = true
                    }
                    .onEnded(onDragEnded)
            )
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        dragging = false

        let dragDirection = drag.predictedEndLocation.y - drag.location.y
        if dragDirection > 0 {
            position = minYPosition
            onCollapse()
        } else {
            position = paddingTop
            onExpand()
        }
    }
}
