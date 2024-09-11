//
//  CardShape.swift
//  SnabbleAssetProviding
//
//  Created by Uwe Tilemann on 16.06.24.
//

import SwiftUI

public struct CardShape: Shape {
    let radius: CGFloat
    let inset: Edge
    
    public enum Edge: Sendable {
        case top
        case bottom
    }
    public init(radius: CGFloat, _ inset: Edge = .bottom) {
        self.radius = radius
        self.inset = inset
    }
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if inset == .bottom {
            let left = CGPoint(x: rect.minX, y: rect.maxY)
            let right = CGPoint(x: rect.maxX, y: rect.maxY)
            let trs = CGPoint(x: rect.maxX, y: rect.minY + radius)
            let trc = CGPoint(x: rect.maxX - radius, y: rect.minY + radius)
            let tls = CGPoint(x: rect.minX + radius, y: rect.minY)
            let tlc = CGPoint(x: rect.minX + radius, y: rect.minY + radius)
            
            path.move(to: left)
            path.addLine(to: right)
            
            path.addLine(to: trs)
            path.addRelativeArc(
                center: trc,
                radius: radius,
                startAngle: Angle.degrees(0),
                delta: Angle.degrees(-90))
            
            path.addLine(to: tls)
            path.addRelativeArc(
                center: tlc,
                radius: radius,
                startAngle: Angle.degrees(-90),
                delta: Angle.degrees(-90))

        } else {
            let left = CGPoint(x: rect.maxX, y: rect.minY)
            let right = CGPoint(x: rect.minX, y: rect.minY)
            
            let trs = CGPoint(x: rect.minX, y: rect.maxY - radius)
            let trc = CGPoint(x: rect.minX + radius, y: rect.maxY - radius)
            let tls = CGPoint(x: rect.maxX - radius, y: rect.maxY)
            let tlc = CGPoint(x: rect.maxX - radius, y: rect.maxY - radius)
            
            path.move(to: left)
            path.addLine(to: right)
            
            path.addLine(to: trs)
            path.addRelativeArc(
                center: trc,
                radius: radius,
                startAngle: Angle.degrees(180),
                delta: Angle.degrees(-90))
            
            path.addLine(to: tls)
            path.addRelativeArc(
                center: tlc,
                radius: radius,
                startAngle: Angle.degrees(90),
                delta: Angle.degrees(-90))
        }
        
        return path
    }
}
