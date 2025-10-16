//
//  PullOverView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

struct DraggableModifier: ViewModifier {
    enum Direction {
        case vertical
        case horizontal
    }
    
    let direction: Direction
    
    @State private var draggedOffset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(
                CGSize(width: direction == .vertical ? 0 : draggedOffset.width,
                       height: direction == .horizontal ? 0 : draggedOffset.height)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.draggedOffset = value.translation
                    }
                    .onEnded { _ in
                        self.draggedOffset = .zero
                    }
            )
    }
}
extension View {
    func dragDirection(_ direction: DraggableModifier.Direction) -> some View {
        modifier(DraggableModifier(direction: direction))
    }
}

extension DragGesture.Value {
    var isVertical: Bool {
        abs(startLocation.y - location.y) > abs(startLocation.x - location.x)
    }
    var isHorizontal: Bool {
        !isVertical
    }
}

struct PullOverView<Content>: View where Content: View {
    @Binding var minHeight: CGFloat
    @Binding var expanded: Bool
    @Binding var paddingTop: CGFloat
    @Binding var position: CGFloat
    let content: () -> Content
    
    init(minHeight: Binding<CGFloat>, 
         expanded: Binding<Bool>,
         paddingTop: Binding<CGFloat>,
         position: Binding<CGFloat>,
         content: @escaping () -> Content
    ) {
        self._minHeight = minHeight
        self._expanded = expanded
        self._paddingTop = paddingTop
        self._position = position
        self.content = content
    }
    
    public var body: some View {
        ModifiedContent(
            content: self.content(),
            modifier: PullView(
                minHeight: $minHeight,
                expanded: $expanded,
                paddingTop: $paddingTop,
                position: $position
            )
        )
    }
}

struct PullView: ViewModifier {
    @SwiftUI.Environment(\.safeAreaInsets) var insets
    
    @Binding var minHeight: CGFloat
    @Binding var expanded: Bool
    @Binding var paddingTop: CGFloat
    @Binding var position: CGFloat

    @State private var dragging = false
    @GestureState private var dragTracker = CGSize.zero
    @State private var minYPosition: CGFloat = 0
    
    func maxHeight(_ geom: GeometryProxy) -> CGFloat {
        geom.size.height
    }
    func setupMinHeight(geom: GeometryProxy) {
        minYPosition = maxHeight(geom) - UITabBarController().height - (minHeight > 0 ? minHeight : paddingTop)
        position = expanded ? paddingTop : minYPosition
    }
    func body(content: Content) -> some View {
        GeometryReader { geom in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: 60, height: 6.0)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .onTapGesture {
                        toggle()
                    }
                content.padding(.top, 16)
            }
            .frame(minWidth: UIScreen.main.bounds.width)
            .background(.regularMaterial)
            .clipShape(CardShape(radius: 24))
            .task {
                setupMinHeight(geom: geom)
            }
            .onChange(of: minHeight) {
                setupMinHeight(geom: geom)
            }
            .onChange(of: paddingTop) {
                setupMinHeight(geom: geom)
            }
            .frame(maxHeight: CGFloat(max(maxHeight(geom) - (position + self.dragTracker.height), 0)))
            .offset(y: max(0, position + self.dragTracker.height))
            .animation(.easeInOut(duration: 0.2), value: position)
            .animation(Animation.interpolatingSpring(stiffness: 250.0, damping: 40.0, initialVelocity: 5.0), value: dragging)
            .opacity(position == 0 ? 0 : 1)
            .simultaneousGesture(DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .updating($dragTracker) { drag, state, _ in
                    if drag.isVertical {
                        state = drag.translation
                    }
                }
                .onChanged { drag in
                    if drag.isVertical {
                        dragging = true
                    }
                }
                .onEnded(onDragEnded)
            )
        }
        
    }
    func expand() {
        expanded = true
        position = paddingTop
    }
    func collapse() {
        expanded = false
        position = minYPosition
    }
    func toggle() {
        if position == minYPosition {
            expand()
        } else {
            collapse()
        }
    }
    private func onDragEnded(drag: DragGesture.Value) {
        dragging = false
        
        guard drag.isVertical else {
            return
        }
        let dragDirection = drag.predictedEndLocation.y - drag.location.y
        // can also calculate drag offset to make it more rigid to shrink and expand
        if dragDirection > 0 {
            position = minYPosition
            collapse()
        } else {
            expand()
        }
    }
}
