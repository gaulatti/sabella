#if canImport(Charts)
import Charts
import SwiftUI

public struct BleeckerChartPoint: Identifiable, Sendable {
    public let id: String; public let series: String; public let label: String; public let x: Double; public let y: Double
    public init(id: String = UUID().uuidString, series: String = "Value", label: String = "", x: Double, y: Double) { self.id = id; self.series = series; self.label = label; self.x = x; self.y = y }
}

public struct BleeckerLineChart: View {
    @Environment(\.colorScheme) private var scheme; let points: [BleeckerChartPoint]; let area: Bool
    public init(_ points: [BleeckerChartPoint], area: Bool = false) { self.points = points; self.area = area }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); Chart(points) { point in LineMark(x: .value("X", point.x), y: .value("Y", point.y)).foregroundStyle(by: .value("Series", point.series)).interpolationMethod(.catmullRom); if area { AreaMark(x: .value("X", point.x), y: .value("Y", point.y)).foregroundStyle(LinearGradient(colors: [p.sea.opacity(0.25), p.sea.opacity(0.02)], startPoint: .top, endPoint: .bottom)).interpolationMethod(.catmullRom) } }.chartForegroundStyleScale(range: [p.sea, p.desert, p.terracotta, p.accentGold]) }
}

public struct BleeckerBarChart: View {
    @Environment(\.colorScheme) private var scheme; let points: [BleeckerChartPoint]
    public init(_ points: [BleeckerChartPoint]) { self.points = points }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); Chart(points) { point in BarMark(x: .value("Label", point.label), y: .value("Value", point.y)).foregroundStyle(by: .value("Series", point.series)).cornerRadius(4) }.chartForegroundStyleScale(range: [p.sea, p.desert, p.terracotta, p.accentGold]) }
}

public struct BleeckerPieChart: View {
    @Environment(\.colorScheme) private var scheme; let points: [BleeckerChartPoint]; let innerRadius: CGFloat
    public init(_ points: [BleeckerChartPoint], innerRadius: CGFloat = 0) { self.points = points; self.innerRadius = innerRadius }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); Chart(points) { point in SectorMark(angle: .value("Value", point.y), innerRadius: .ratio(innerRadius), angularInset: 1).foregroundStyle(by: .value("Series", point.series)).cornerRadius(3) }.chartForegroundStyleScale(range: [p.sea, p.desert, p.terracotta, p.accentGold, p.accentOxblood]) }
}

public struct BleeckerScatterChart: View {
    @Environment(\.colorScheme) private var scheme; let points: [BleeckerChartPoint]
    public init(_ points: [BleeckerChartPoint]) { self.points = points }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); Chart(points) { point in PointMark(x: .value("X", point.x), y: .value("Y", point.y)).foregroundStyle(by: .value("Series", point.series)) }.chartForegroundStyleScale(range: [p.sea, p.desert, p.terracotta]) }
}

public struct BleeckerSparkline: View {
    let values: [Double]
    public init(_ values: [Double]) { self.values = values }
    public var body: some View { BleeckerLineChart(Array(values.enumerated()).map { BleeckerChartPoint(x: Double($0.offset), y: $0.element) }).chartXAxis(.hidden).chartYAxis(.hidden).accessibilityLabel("Trend") }
}
#endif
