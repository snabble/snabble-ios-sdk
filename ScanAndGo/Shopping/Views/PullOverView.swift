//
//  PullOverView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

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
    @Binding var isDragging: Bool
    let content: () -> Content
    
    init(minHeight: Binding<CGFloat>, 
         expanded: Binding<Bool>,
         paddingTop: Binding<CGFloat>,
         position: Binding<CGFloat>,
         isDragging: Binding<Bool>,
         content: @escaping () -> Content
    ) {
        self._minHeight = minHeight
        self._expanded = expanded
        self._paddingTop = paddingTop
        self._position = position
        self._isDragging = isDragging
        self.content = content
    }
    
    public var body: some View {
        ModifiedContent(
            content: self.content(),
            modifier: PullView(
                minHeight: $minHeight,
                expanded: $expanded,
                paddingTop: $paddingTop,
                position: $position,
                isDragging: $isDragging
            )
        )
    }
}

struct PullView: ViewModifier {
    // Top padding added above the content to make room for the drag handle
    static let contentTopPadding: CGFloat = 16

    @Binding var minHeight: CGFloat
    @Binding var expanded: Bool
    @Binding var paddingTop: CGFloat
    @Binding var position: CGFloat
    @Binding var isDragging: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var minYPosition: CGFloat = 0
    @State private var directionUp: Bool = false
    
    func maxHeight(_ geom: GeometryProxy) -> CGFloat {
        geom.size.height
    }
    // animated: true for user-visible height changes (minHeight, paddingTop).
    // false for initial layout and device rotation — those should be instant.
    func setupMinHeight(geom: GeometryProxy, animated: Bool = false) {
        guard geom.size.height > 0, !isDragging else { return }
        // When minHeight hasn't been measured yet, offer half the screen so content
        // can render at its natural size and report a correct measurement.
        // Using only paddingTop (20pt) would compress content and cause the measured
        // height to oscillate upward frame by frame until convergence.
        let effective = minHeight > paddingTop ? minHeight : geom.size.height / 2
        let newMinYPosition = maxHeight(geom) - effective
        let newPosition = expanded ? paddingTop : newMinYPosition
        guard minYPosition != newMinYPosition || position != newPosition else { return }
        minYPosition = newMinYPosition
        if animated {
            withAnimation(.default) { position = newPosition }
        } else {
            position = newPosition
        }
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
                content.padding(.top, PullView.contentTopPadding)
            }
            .frame(minWidth: UIScreen.main.bounds.width)
            .background(.regularMaterial)
            .clipShape(CardShape(radius: 24))
            .onAppear {
                setupMinHeight(geom: geom)
            }
            .onChange(of: geom.size.height) {
                setupMinHeight(geom: geom)
            }
            .onChange(of: minHeight) {
                setupMinHeight(geom: geom, animated: true)
            }
            .onChange(of: paddingTop) {
                setupMinHeight(geom: geom, animated: true)
            }
            .onChange(of: expanded) {
                setupMinHeight(geom: geom)
            }
            .frame(maxHeight: CGFloat(max(maxHeight(geom) - (position + dragOffset), 0)))
            .offset(y: max(0, position + dragOffset))
            .opacity(position == 0 ? 0 : 1)
            .simultaneousGesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged { drag in
                    guard drag.isVertical else { return }
                    isDragging = true
                    dragOffset = drag.translation.height
                    directionUp = drag.translation.height > 0
                }
                .onEnded { drag in
                    isDragging = false
                    guard drag.isVertical else {
                        dragOffset = 0
                        return
                    }
                    // Commit the current visual position before animating to the target.
                    // Without this, resetting dragOffset to 0 causes a visible jump because
                    // the animation would start from position (the old stored value) instead
                    // of from where the view actually is on screen.
                    let currentVisual = position + dragOffset
                    let shouldCollapse = directionUp
                    let targetPosition = shouldCollapse ? minYPosition : paddingTop
                    let targetExpanded = !shouldCollapse

                    position = currentVisual
                    dragOffset = 0

                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            position = targetPosition
                            expanded = targetExpanded
                        }
                    }
                }
            )
        }
    }
    func expand() {
        withAnimation(.easeInOut(duration: 0.2)) {
            expanded = true
            position = paddingTop
        }
    }
    func collapse() {
        withAnimation(.easeInOut(duration: 0.2)) {
            expanded = false
            position = minYPosition
        }
    }
    func toggle() {
        if position == minYPosition {
            expand()
        } else {
            collapse()
        }
    }
}
