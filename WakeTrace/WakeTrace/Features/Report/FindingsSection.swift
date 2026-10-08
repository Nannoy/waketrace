import SwiftUI

struct FindingsSection: View {
    let findings: [Finding]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("Findings")
                .sectionHeader()

            if findings.isEmpty {
                WTCard {
                    HStack(spacing: DS.md) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.statusNormal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nothing to report")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.wtLabel)
                            Text("Your Mac slept well last night.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.wtLabelSec)
                        }
                    }
                }
            } else {
                VStack(spacing: DS.xs) {
                    ForEach(findings) { finding in
                        FindingRow(finding: finding)
                    }
                }
            }
        }
    }
}

struct FindingRow: View {
    let finding: Finding
    @State private var isExpanded = false

    var body: some View {
        WTCard(padding: 0) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 0) {
                        SeverityBar(severity: finding.severity)
                            .frame(height: isExpanded ? nil : 52)
                            .padding(.vertical, DS.sm)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: DS.sm) {
                                Image(systemName: categoryIcon(finding.category))
                                    .font(.system(size: 12))
                                    .foregroundStyle(finding.severity.color)
                                    .frame(width: 16)
                                Text(finding.headline)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.wtLabel)
                                    .lineLimit(isExpanded ? nil : 1)
                                Spacer()
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.wtLabelTert)
                            }

                            if !isExpanded {
                                Text(finding.explanation)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.wtLabelSec)
                                    .lineLimit(1)
                                    .padding(.leading, 24)
                            }
                        }
                        .padding(.vertical, DS.sm + 2)
                        .padding(.horizontal, DS.md)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    WTDivider()
                        .padding(.leading, DS.md + 3)

                    VStack(alignment: .leading, spacing: DS.sm) {
                        Text(finding.explanation)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.wtLabelSec)
                            .fixedSize(horizontal: false, vertical: true)

                        if let rec = finding.recommendation {
                            HStack(alignment: .top, spacing: DS.sm) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.top, 1)
                                Text(rec)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.wtLabelSec)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(DS.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.accentColor.opacity(0.06))
                            )
                        }

                        HStack(spacing: DS.sm) {
                            Text(finding.severity.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(finding.severity.color)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(finding.severity.color.opacity(0.10)))

                            Text(finding.confidenceLabel)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.wtLabelTert)
                        }
                    }
                    .padding(.leading, DS.md + 3)
                    .padding(.trailing, DS.md)
                    .padding(.vertical, DS.md)
                }
            }
        }
    }

    private func categoryIcon(_ cat: FindingCategory) -> String {
        switch cat {
        case .batteryDrain:       return "battery.25percent"
        case .bluetoothWake:      return "antenna.radiowaves.left.and.right"
        case .networkWake:        return "wifi"
        case .maintenanceWake:    return "gearshape"
        case .frequentWake:       return "exclamationmark.triangle"
        case .sleepAssertion:     return "nosign"
        case .applicationActivity: return "app.badge"
        case .shortSleep:         return "clock"
        case .normalSession:      return "checkmark.circle"
        }
    }
}
