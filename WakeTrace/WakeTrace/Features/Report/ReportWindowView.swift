import SwiftUI

struct ReportWindowView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let session = appState.selectedSession ?? appState.lastSession {
                ReportView(session: session)
            } else {
                emptyState
            }
        }
        .background(Color.wtBackground)
        .frame(minWidth: 680, minHeight: 560)
    }

    private var emptyState: some View {
        VStack(spacing: DS.md) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 40))
                .foregroundStyle(Color.wtLabelTert)
            Text("No report selected")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.wtLabel)
            Text("Select a session from History to view its report.")
                .font(.system(size: 13))
                .foregroundStyle(Color.wtLabelSec)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
