import SwiftUI

/// The quirky feature: a draggable "float line" puck on a horizontal
/// timeline. Dragging it simulates the next expected payment arriving on a
/// different (typically later) date, and — for Pro — the safe-to-spend
/// figure recalculates live, continuously, before the finger is lifted.
struct FloatLineTimelineView: View {
    @EnvironmentObject private var store: CashFlowStore
    @EnvironmentObject private var storeManager: StoreManager

    @State private var dragDays: Double?
    @State private var showSetExpected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Float line")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if store.nextExpected != nil {
                    Button("Change") { showSetExpected = true }
                        .font(.footnote)
                        .foregroundStyle(EbblineTheme.aqua)
                }
            }

            if let nextExpected = store.nextExpected {
                timeline(for: nextExpected)
                    .onChange(of: nextExpected) { _, _ in dragDays = nil }
            } else {
                emptyState
            }
        }
        .padding(20)
        .ebblineGlass()
        .sheet(isPresented: $showSetExpected) {
            SetExpectedPaymentView()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set your next expected payment to unlock the float line — drag it to simulate a late payment and watch safe-to-spend react live.")
                .font(.footnote)
                .foregroundStyle(EbblineTheme.foam.opacity(0.8))
            Button {
                showSetExpected = true
            } label: {
                Text("Set next expected payment")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EbblineTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(EbblineTheme.aqua, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func timeline(for nextExpected: ExpectedPayment) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        let originalDays = max(1, daysBetween(today, nextExpected.expectedDate))
        let totalDays = Double(max(originalDays * 2, originalDays + 14))
        let currentDragDays = dragDays ?? Double(originalDays)
        let hypotheticalDate = Calendar.current.date(byAdding: .day, value: Int(currentDragDays.rounded()), to: today) ?? nextExpected.expectedDate

        return VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                let width = geo.size.width
                let puckX = width * CGFloat(currentDragDays / totalDays)

                ZStack(alignment: .leading) {
                    WaveDivider(amplitude: 3, wavelength: 36, phase: 0)
                        .stroke(EbblineTheme.foam.opacity(0.35), lineWidth: 2)
                        .frame(height: 10)
                        .frame(maxHeight: .infinity, alignment: .center)

                    Circle()
                        .fill(EbblineTheme.foam)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(EbblineTheme.deepTeal.opacity(0.35), lineWidth: 3))
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .offset(x: min(max(puckX - 13, -13), width - 13))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let clampedX = min(max(drag.location.x, 0), width)
                                    dragDays = max(0, Double(clampedX / width) * totalDays)
                                }
                                .onEnded { _ in
                                    if let value = dragDays {
                                        dragDays = value.rounded()
                                    }
                                }
                        )
                }
            }
            .frame(height: 32)

            HStack {
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(EbblineTheme.foam.opacity(0.6))
                Spacer()
                Text("+\(Int(totalDays)) days")
                    .font(.caption2)
                    .foregroundStyle(EbblineTheme.foam.opacity(0.6))
            }

            resultPanel(hypotheticalDate: hypotheticalDate, nextExpected: nextExpected, today: today)
        }
    }

    @ViewBuilder
    private func resultPanel(hypotheticalDate: Date, nextExpected: ExpectedPayment, today: Date) -> some View {
        if storeManager.isPro {
            let hypothetical = ExpectedPayment(
                source: nextExpected.source,
                amount: nextExpected.amount,
                expectedDate: hypotheticalDate
            )
            let projected = CashFlowEngine.safeToSpend(
                events: store.events,
                bills: store.bills,
                nextExpected: hypothetical,
                asOf: today,
                billAware: true
            )
            let raw = CashFlowEngine.rawProjectedBalance(
                events: store.events,
                bills: store.bills,
                until: hypotheticalDate,
                asOf: today
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("If \(nextExpected.source) lands \(hypotheticalDate.formatted(date: .abbreviated, time: .omitted)):")
                    .font(.caption)
                    .foregroundStyle(EbblineTheme.foam.opacity(0.8))
                HStack {
                    Text("Safe to spend would be")
                        .font(.footnote)
                        .foregroundStyle(EbblineTheme.foam.opacity(0.7))
                    Spacer()
                    Text(max(0, projected), format: .currency(code: "USD"))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(raw < 0 ? EbblineTheme.coral : .white)
                        .contentTransition(.numericText())
                }
                if raw < 0 {
                    Text("That's a shortfall of \(abs(raw), format: .currency(code: "USD")) before that payment lands.")
                        .font(.caption2)
                        .foregroundStyle(EbblineTheme.coral)
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                Text("Pro recalculates safe-to-spend live as you drag")
                    .font(.caption)
            }
            .foregroundStyle(EbblineTheme.foam.opacity(0.6))
        }
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
