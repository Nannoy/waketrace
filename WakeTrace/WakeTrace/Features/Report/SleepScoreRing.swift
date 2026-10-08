import SwiftUI

struct SleepScoreRing: View {
    let session: SleepReport
    @State private var progress: Double = 0

    var score: Int {
        var s = 100
        switch session.findings.map(\.severity).max() ?? .normal {
        case .critical: s -= 40
        case .elevated: s -= 25
        case .notice:   s -= 12
        case .normal:   break
        }
        if session.durationHours > 0 && session.durationHours < 2 { s -= 20 }
        else if session.durationHours > 0 && session.durationHours < 4 { s -= 8 }
        if session.wakeCount > 8      { s -= 15 }
        else if session.wakeCount > 4 { s -= 7 }
        return max(5, min(100, s))
    }

    var scoreColor: Color {
        switch score {
        case 80...: return Color(red: 0.18, green: 0.84, blue: 0.58)
        case 55..<80: return Color(red: 0.98, green: 0.76, blue: 0.22)
        default:     return Color(red: 0.95, green: 0.38, blue: 0.38)
        }
    }

    var scoreLabel: String {
        switch score {
        case 85...: return "Great night"
        case 70..<85: return "Decent sleep"
        case 50..<70: return "Could be better"
        default:     return "Rough night"
        }
    }

    var body: some View {
        ZStack {
            // Track (270° = 0.75 of circle, starting at bottom-left)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.wtBorder.opacity(0.20), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(135))

            // Score fill
            Circle()
                .trim(from: 0, to: 0.75 * (Double(score) / 100.0) * progress)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(135))
                .shadow(color: scoreColor.opacity(0.45), radius: 5)

            // Center
            VStack(spacing: 1) {
                Text("\(score)")
                    .font(.system(size: 22, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.wtLabel)
                Text("/ 100")
                    .font(.system(size: 7, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.wtLabelTert)
            }
        }
        .frame(width: 88, height: 88)
        // Score label sits below the ring
        // (accessed by ReportView via scoreLabel property)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.1)) {
                progress = 1.0
            }
        }
    }
}
