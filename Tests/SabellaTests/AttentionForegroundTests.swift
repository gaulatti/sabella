import Testing
import SwiftUI
import Sabella
#if os(macOS)
import AppKit

@Test @MainActor func attentionDefaultTextRemainsReadableInBothAppearances() throws {
    let glyph = Text("H").font(.system(size: 32, weight: .bold))
        .frame(width: 44, height: 44)
    let mask = try attentionForegroundPixels(glyph.padding(17)
        .foregroundStyle(.white).background(.black))
    let cores = stride(from: 0, to: mask.count, by: 4).filter {
        mask[$0] >= 250 && mask[$0 + 1] >= 250 && mask[$0 + 2] >= 250
    }
    #expect(cores.count > 40, "The contrast check must sample actual solid glyph pixels")
    for scheme in [ColorScheme.light, .dark] {
        for hue in stride(from: 0.0, to: 360, by: 60) {
            for intensity in [0.0, 5, 10] {
                for secondary in [false, true] {
                    let text = secondary ? AnyView(glyph.foregroundStyle(.secondary)) : AnyView(glyph)
                    let painted = try attentionForegroundPixels(
                        BleeckerAttentionSurface(hue: hue, intensity: intensity, density: .compact) { text }
                            .environment(\.colorScheme, scheme).background(.white))
                    let background = try attentionForegroundPixels(
                        BleeckerAttentionSurface(hue: hue, intensity: intensity, density: .compact) {
                            Color.clear.frame(width: 44, height: 44)
                        }.environment(\.colorScheme, scheme).background(.white))
                    #expect(painted.count == mask.count && background.count == mask.count)
                    let minimum = cores.map { offset in
                        let foreground = attentionTextLuminance(painted, at: offset)
                        let behind = attentionTextLuminance(background, at: offset)
                        return (max(foreground, behind) + 0.05) / (min(foreground, behind) + 0.05)
                    }.min() ?? 0
                    #expect(minimum >= 4.5,
                        "Native text contrast \(minimum) at hue \(hue), intensity \(intensity), \(scheme), secondary=\(secondary)")
                }
            }
        }
    }
}

@Test @MainActor func attentionRetainsExplicitChildForeground() throws {
    let glyph = Text("H").font(.system(size: 32, weight: .bold)).frame(width: 44, height: 44)
    let mask = try attentionForegroundPixels(glyph.padding(17).foregroundStyle(.white).background(.black))
    let cores = stride(from: 0, to: mask.count, by: 4).filter {
        mask[$0] >= 250 && mask[$0 + 1] >= 250 && mask[$0 + 2] >= 250
    }
    #expect(cores.count > 40)
    for scheme in [ColorScheme.light, .dark] {
        let pixels = try attentionForegroundPixels(
            BleeckerAttentionSurface(hue: 210, intensity: 5, density: .compact) {
                glyph.foregroundStyle(.red)
            }.environment(\.colorScheme, scheme).background(.white))
        #expect(cores.allSatisfy { Int(pixels[$0]) > 2 * Int(pixels[$0 + 1]) && Int(pixels[$0]) > 2 * Int(pixels[$0 + 2]) },
                "The surface must not replace a child's explicit red foreground")
    }
}

@MainActor private func attentionForegroundPixels<V: View>(_ view: V) throws -> [UInt8] {
    let renderer = ImageRenderer(content: view); renderer.scale = 1
    let image = try #require(renderer.cgImage)
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    try bytes.withUnsafeMutableBytes { buffer in
        let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return bytes
}

private func attentionTextLuminance(_ pixels: [UInt8], at offset: Int) -> Double {
    func linear(_ byte: UInt8) -> Double {
        let value = Double(byte) / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(pixels[offset]) + 0.7152 * linear(pixels[offset + 1]) + 0.0722 * linear(pixels[offset + 2])
}
#endif
