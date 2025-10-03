//
//  TimerDisplayView.swift
//  LaundryPets
//
//  Optimized timer display component for smooth scrolling performance
//

import SwiftUI

/// Isolated timer display component with Equatable conformance for optimal performance
/// Prevents unnecessary redraws of parent views during scroll operations
struct TimerDisplayView: View, Equatable {
    let timeRemaining: TimeInterval
    let isActive: Bool
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: TimerDisplayView, rhs: TimerDisplayView) -> Bool {
        // Only redraw if time remaining changes significantly (round to nearest second)
        let lhsSeconds = Int(lhs.timeRemaining)
        let rhsSeconds = Int(rhs.timeRemaining)
        return lhsSeconds == rhsSeconds && lhs.isActive == rhs.isActive
    }
    
    // MARK: - Body
    
    var body: some View {
        if isActive {
            Text(formatTime(timeRemaining))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .monospacedDigit()
                .drawingGroup() // Rasterize for better performance
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TimerDisplayView(timeRemaining: 3661, isActive: true) // 1:01:01
        TimerDisplayView(timeRemaining: 125, isActive: true)  // 2:05
        TimerDisplayView(timeRemaining: 30, isActive: true)   // 0:30
        TimerDisplayView(timeRemaining: 0, isActive: false)   // Inactive
    }
    .padding()
}
