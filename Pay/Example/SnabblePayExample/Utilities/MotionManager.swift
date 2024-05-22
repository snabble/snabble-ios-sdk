//
//  MotionManager.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//
import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    static let shared = MotionManager()
    
    private let manager: CMMotionManager
    let formatter: NumberFormatter
    
    @Published var xCoordinate = 0.0
    @Published var yCoordinate = 0.0

    init() {
        self.formatter = NumberFormatter()
        self.formatter.maximumFractionDigits = 2
        
        self.manager = CMMotionManager()
        self.manager.deviceMotionUpdateInterval = 1 / 30
        self.manager.startDeviceMotionUpdates(to: .main) { [weak self] (data, _) in
            guard let motion = data?.attitude else { return }
            
            self?.xCoordinate = motion.roll
            self?.yCoordinate = motion.pitch
        }
    }
}
