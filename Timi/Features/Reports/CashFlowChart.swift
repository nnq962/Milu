import SwiftUI

/// "Dòng tiền" on Báo cáo (user request 2026-11-08, a flow chart as in money apps): where the
/// period's money came from on the left (income by group, and "Chi vượt thu" when more went out
/// than came in), where it went on the right (spending by group, and "Còn dư" when less went out),
/// each source spread over the uses in proportion, since money in is not tied to any one spending.
/// The right side's colours are the list's dots under it; money in and kept is green, money taken
/// from what was there grey. The bars stand as near the edges as their names allow; tapping a
/// name or a bar lights its bands and dims the rest, tapping it again (or empty room) lets go
/// (user request 2026-11-08).
struct CashFlowChart: View {
    struct Node: Identifiable {
        /// What a node stands for, which says what its share is of.
        enum Kind { case income, over, spending, kept }

        let id: String
        let name: String
        let amount: Double
        let color: Color
        let kind: Kind
    }

    let sources: [Node]
    let sinks: [Node]
    /// A new value (the period) lets go of the pick, even where the new nodes have the same ids
    /// (review 2026-11-08: "Đổi kỳ thì tự bỏ chọn").
    var resetKey: AnyHashable = 0

    /// The node tapped: its bands lit, the others dimmed.
    @State private var selected: String?
    /// How wide each side's names are, so the bars stand right beside them.
    @State private var sourceWidth: CGFloat = 0
    @State private var sinkWidth: CGFloat = 0

    /// The least room a bar takes in its column: a name and its amount, so each name sits
    /// level with its own bar however small (Simulator check 2026-11-08: a small group's name
    /// was pushed up beside the bar above it).
    @ScaledMetric(relativeTo: .caption) private var pitch: CGFloat = 46
    /// The same when a name runs to two lines (wider than its column may be), so names never
    /// overlap (review 2026-11-08).
    @ScaledMetric(relativeTo: .caption) private var twoLinePitch: CGFloat = 64
    /// The chart's width, to know whether a name will wrap.
    @State private var width: CGFloat = 0
    /// What the whole sum is drawn as, before the room the names need is added.
    @ScaledMetric(relativeTo: .caption) private var span: CGFloat = 150
    private let nodeWidth: CGFloat = 6
    private let nodeGap: CGFloat = 8
    private let labelGap: CGFloat = Spacing.s
    /// At most this share of the width for one side's names; a longer name wraps.
    private let widestLabels: CGFloat = 0.36

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            // At the accessibility sizes the names had no room beside the bars (cut short, laid
            // over each other): the same figures as two plain lists (review 2026-11-08).
            if dynamicTypeSize.isAccessibilitySize {
                lists
            } else {
                chart
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dòng tiền")
        .accessibilityValue(spoken)
        // Another period's nodes: what was picked may not be there (review 2026-11-08: every
        // band went faint with nothing lit).
        .onChange(of: sources.map(\.id) + sinks.map(\.id)) { selected = nil }
        .onChange(of: resetKey) { selected = nil }
    }

    /// The node picked, if it is still drawn.
    private var picked: Node? {
        selected.flatMap { id in (sources + sinks).first { $0.id == id } }
    }

    private var chart: some View {
        let cap = width * widestLabels
        let wraps = width > 0 && (sourceWidth > cap || sinkWidth > cap)
        let rows = Rows(sources: sources, sinks: sinks, span: span, pitch: wraps ? twoLinePitch : pitch, gap: nodeGap)
        return VStack(spacing: Spacing.s) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let left = min(sourceWidth, width * widestLabels)
                let right = min(sinkWidth, width * widestLabels)
                let plan = Plan(sources: sources, sinks: sinks, rows: rows,
                                left: left + labelGap, right: width - right - labelGap, nodeWidth: nodeWidth)
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in draw(plan, in: &context) }
                        .contentShape(Rectangle())
                        .onTapGesture { location in pick(plan.node(at: location)) }
                    StackedLabels {
                        ForEach(Array(sources.enumerated()), id: \.element.id) { index, node in
                            label(node, alignment: .trailing)
                                .layoutValue(key: CenterY.self, value: plan.sourceRects[index].midY)
                        }
                    }
                    .frame(width: left, height: geometry.size.height)
                    StackedLabels {
                        ForEach(Array(sinks.enumerated()), id: \.element.id) { index, node in
                            label(node, alignment: .leading)
                                .layoutValue(key: CenterY.self, value: plan.sinkRects[index].midY)
                        }
                    }
                    .frame(width: right, height: geometry.size.height)
                    .offset(x: width - right)
                }
            }
            .frame(height: rows.height)
            .background { measure }
            // Unseen until the names are measured: the first frame had them at no width.
            .opacity(sourceWidth > 0 && sinkWidth > 0 ? 1 : 0)
            detail
            HStack {
                Text("Tiền vào")
                Spacer()
                Text("Tiền ra")
            }
            .textRole(.footnote)
            .foregroundStyle(Palette.secondaryLabel)
            .accessibilityHidden(true)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// What the picked node is, in full and as a share of its side (review 2026-11-08: the lit
    /// bands alone said nothing the bar did not); before a pick, that there is something to tap.
    private var detail: some View {
        Group {
            if let picked {
                Text(detailText(picked))
                    .foregroundStyle(Palette.label)
            } else {
                Text("Chạm vào một mục để xem chi tiết")
                    .foregroundStyle(Palette.secondaryLabel)
            }
        }
        .textRole(.caption)
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// Both sides as lists, for the accessibility sizes: each name with its colour and full amount.
    private var lists: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            list("Tiền vào", sources)
            list("Tiền ra", sinks)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func list(_ title: String, _ nodes: [Node]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .textRole(.footnote)
                .foregroundStyle(Palette.secondaryLabel)
            ForEach(nodes) { node in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    LegendDot(color: node.color)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(node.name)
                            .textRole(.body)
                        Text(node.amount.vnd)
                            .textRole(.caption)
                            .foregroundStyle(Palette.secondaryLabel)
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    /// The names at their own width, unseen, to size each side's column.
    private var measure: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .trailing, spacing: 0) { ForEach(sources) { labelText($0).fixedSize() } }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { sourceWidth = $0 }
            VStack(alignment: .leading, spacing: 0) { ForEach(sinks) { labelText($0).fixedSize() } }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { sinkWidth = $0 }
        }
        .fixedSize()
        .hidden()
        .accessibilityHidden(true)
    }

    /// "Tiền vào: Lương 850.000 đồng. Tiền ra: Mua sắm 980.000 đồng, …"
    /// "Còn dư" and "Chi vượt thu" said apart: drawn on the two sides, they are neither money
    /// out nor money in (review 2026-11-09).
    private var spoken: String {
        let list = { (nodes: [Node]) in nodes.map { "\($0.name) \(MoneyText.spoken($0.amount))" }.joined(separator: ", ") }
        let rest = (sources + sinks).filter { $0.kind == .kept || $0.kind == .over }
        return ["Tiền vào: \(list(sources.filter { $0.kind == .income })).",
                "Tiền ra: \(list(sinks.filter { $0.kind == .spending })).",
                rest.isEmpty ? nil : "\(list(rest))."].compactMap { $0 }.joined(separator: " ")
    }

    /// "Ăn uống: 836.200đ · 37% tổng chi", the share the list under the chart gives; income as a
    /// share of what came in, "Còn dư" of it too; "Chi vượt thu" its amount alone (review
    /// 2026-11-08: shares of the larger side disagreed with the list, and "Còn dư" read "tiền ra").
    private func detailText(_ node: Node) -> String {
        let received = sources.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let spent = sinks.filter { $0.kind == .spending }.reduce(0) { $0 + $1.amount }
        let share: String? = switch node.kind {
        case .spending: spent > 0 ? "\((node.amount / spent).percentText) tổng chi" : nil
        case .income: received > 0 ? "\((node.amount / received).percentText) tổng thu" : nil
        case .kept: received > 0 ? "\((node.amount / received).percentText) tổng thu" : nil
        case .over: nil
        }
        return ["\(node.name): \(node.amount.vnd)", share].compactMap { $0 }.joined(separator: " · ")
    }

    /// The same node again, or empty room, lets go. At once, labels and bands alike: the canvas
    /// cannot fade, so a fading label ran behind its bands (review 2026-11-08). A tick on the tap
    /// itself, not on any change of the pick: a new period letting go buzzed too.
    private func pick(_ id: String?) {
        let new = id == picked?.id ? nil : id
        guard new != selected else { return }
        selected = new
        Haptics.selection()
    }

    /// Dimmed when another node of its own side is picked; the other side all feeds it.
    private func isDimmed(_ node: Node) -> Bool {
        guard let picked, picked.id != node.id else { return false }
        let side = sources.contains { $0.id == node.id } ? sources : sinks
        return side.contains { $0.id == picked.id }
    }

    /// The name, and under it the amount short ("980k"): the room is a column's, not a row's.
    private func label(_ node: Node, alignment: HorizontalAlignment) -> some View {
        Button { pick(node.id) } label: {
            labelText(node, alignment: alignment)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
                // A finger's reach past the two short lines.
                .contentShape(Rectangle().inset(by: -Spacing.xs))
        }
        .buttonStyle(.plain)
        .opacity(isDimmed(node) ? 0.4 : 1)
    }

    private func labelText(_ node: Node, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(node.name)
                .textRole(.caption)
                .foregroundStyle(Palette.label)
                .lineLimit(2)
            Text(node.amount.vndCompact)
                .textRole(.footnote)
                .foregroundStyle(Palette.secondaryLabel)
                .monospacedDigit()
        }
    }

    private func draw(_ plan: Plan, in context: inout GraphicsContext) {
        // A band thinner than a hairline read as a stray thread (Simulator check 2026-11-08);
        // its room stays, so every other band keeps its place.
        for flow in plan.flows where flow.from.height >= 0.75 {
            var path = Path()
            let midX = (flow.from.minX + flow.to.minX) / 2
            path.move(to: CGPoint(x: flow.from.minX, y: flow.from.minY))
            path.addCurve(to: CGPoint(x: flow.to.minX, y: flow.to.minY),
                          control1: CGPoint(x: midX, y: flow.from.minY), control2: CGPoint(x: midX, y: flow.to.minY))
            path.addLine(to: CGPoint(x: flow.to.minX, y: flow.to.maxY))
            path.addCurve(to: CGPoint(x: flow.from.minX, y: flow.from.maxY),
                          control1: CGPoint(x: midX, y: flow.to.maxY), control2: CGPoint(x: midX, y: flow.from.maxY))
            path.closeSubpath()
            let opacity: Double = switch picked?.id {
            case nil: 0.28
            case flow.sourceID, flow.sinkID: 0.5
            default: 0.06
            }
            context.fill(path, with: .color(flow.color.opacity(opacity)))
        }
        // Rounded on the outer side only: the side the bands meet stays square, so a band's top
        // and bottom run straight into the bar's corners (user report 2026-11-08).
        let corner: CGFloat = 3
        for (index, rect) in plan.sourceRects.enumerated() {
            let node = sources[index]
            let bar = UnevenRoundedRectangle(topLeadingRadius: corner, bottomLeadingRadius: corner).path(in: rect)
            context.fill(bar, with: .color(node.color.opacity(isDimmed(node) ? 0.35 : 1)))
        }
        for (index, rect) in plan.sinkRects.enumerated() {
            let node = sinks[index]
            let bar = UnevenRoundedRectangle(bottomTrailingRadius: corner, topTrailingRadius: corner).path(in: rect)
            context.fill(bar, with: .color(node.color.opacity(isDimmed(node) ? 0.35 : 1)))
        }
    }

    /// The bars' heights and places down each column. One scale for both sides, which add up
    /// to the same sum; each bar gets at least `pitch` of room, centred in it; the chart is as
    /// tall as the taller column, the other one centred.
    private struct Rows {
        var sources: [ClosedRange<CGFloat>] = []
        var sinks: [ClosedRange<CGFloat>] = []
        var height: CGFloat = 0
        var scale: CGFloat = 0

        init(sources: [Node], sinks: [Node], span: CGFloat, pitch: CGFloat, gap: CGFloat) {
            let total = max(sources.reduce(0) { $0 + $1.amount }, sinks.reduce(0) { $0 + $1.amount }, 1)
            let scale: CGFloat = span / CGFloat(total)
            let slots = { (nodes: [Node]) -> [CGFloat] in nodes.map { max(CGFloat($0.amount) * scale + gap, pitch) } }
            let left = slots(sources), right = slots(sinks)
            height = max(left.reduce(0, +), right.reduce(0, +))
            func place(_ nodes: [Node], _ slots: [CGFloat]) -> [ClosedRange<CGFloat>] {
                var y = (height - slots.reduce(0, +)) / 2
                return zip(nodes, slots).map { node, slot in
                    let bar = CGFloat(node.amount) * scale
                    let top: CGFloat = y + (slot - bar) / 2
                    y += slot
                    return top...(top + bar)
                }
            }
            self.sources = place(sources, left)
            self.sinks = place(sinks, right)
            self.scale = scale
        }
    }

    /// Where every bar and band goes across the width.
    private struct Plan {
        struct Flow {
            /// Zero-width rects at the band's two ends: x where it starts, its top and bottom.
            let from: CGRect
            let to: CGRect
            let color: Color
            let sourceID: String
            let sinkID: String
        }

        var sourceRects: [CGRect] = []
        var sinkRects: [CGRect] = []
        var flows: [Flow] = []
        var sourceIDs: [String] = []
        var sinkIDs: [String] = []

        /// The bar under a finger, with room either side of its thin width; nil for empty room.
        func node(at point: CGPoint) -> String? {
            let reach: CGFloat = 16
            if let index = sourceRects.firstIndex(where: { $0.insetBy(dx: -reach, dy: -4).contains(point) }) {
                return sourceIDs[index]
            }
            if let index = sinkRects.firstIndex(where: { $0.insetBy(dx: -reach, dy: -4).contains(point) }) {
                return sinkIDs[index]
            }
            return nil
        }

        init(sources: [Node], sinks: [Node], rows: Rows, left: CGFloat, right: CGFloat, nodeWidth: CGFloat) {
            let total = max(sources.reduce(0) { $0 + $1.amount }, sinks.reduce(0) { $0 + $1.amount }, 1)
            let rect = { (x: CGFloat, range: ClosedRange<CGFloat>) in
                CGRect(x: x, y: range.lowerBound, width: nodeWidth, height: range.upperBound - range.lowerBound)
            }
            sourceIDs = sources.map(\.id)
            sinkIDs = sinks.map(\.id)
            sourceRects = rows.sources.map { rect(left, $0) }
            sinkRects = rows.sinks.map { rect(right - nodeWidth, $0) }
            // Each source's band to each use, in proportion; stacked in order at both ends.
            var sourceTop = sourceRects.map(\.minY)
            var sinkTop = sinkRects.map(\.minY)
            for (i, source) in sources.enumerated() {
                for (j, sink) in sinks.enumerated() {
                    let thickness = CGFloat(source.amount * sink.amount / total) * rows.scale
                    guard thickness > 0 else { continue }
                    flows.append(Flow(from: CGRect(x: sourceRects[i].maxX, y: sourceTop[i], width: 0, height: thickness),
                                      to: CGRect(x: sinkRects[j].minX, y: sinkTop[j], width: 0, height: thickness),
                                      color: sink.color, sourceID: source.id, sinkID: sink.id))
                    sourceTop[i] += thickness
                    sinkTop[j] += thickness
                }
            }
        }
    }
}

/// Where a label would like its middle: level with its bar.
nonisolated private struct CenterY: LayoutValueKey {
    static let defaultValue: CGFloat = 0
}

/// Names in a column, each level with its bar where there is room, pushed apart where bars sit
/// close (a small group under a big one), and kept inside the height.
private struct StackedLabels: Layout {
    private let spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = ProposedViewSize(width: bounds.width, height: nil)
        let heights = subviews.map { $0.sizeThatFits(width).height }
        var tops = zip(subviews, heights).map { $0[CenterY.self] - $1 / 2 }
        // Down: no label over the one before it.
        for index in tops.indices {
            let floor = index == 0 ? 0 : tops[index - 1] + heights[index - 1] + spacing
            tops[index] = max(tops[index], floor)
        }
        // Up: none past the foot, none past the one before it.
        for index in tops.indices.reversed() {
            let ceiling = index == tops.count - 1 ? bounds.height - heights[index] : tops[index + 1] - spacing - heights[index]
            tops[index] = max(min(tops[index], ceiling), 0)
        }
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX, y: bounds.minY + tops[index]),
                          proposal: ProposedViewSize(width: bounds.width, height: heights[index]))
        }
    }
}
