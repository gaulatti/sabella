import Foundation
import Testing
import SwiftUI
#if os(macOS)
import AppKit
#endif
@testable import Sabella

@Test func attentionColorsMatchThePinnedProducerInChrome() throws {
    struct Fixture: Decodable {
        struct Producer: Decodable { let revision: String; let source_sha256: String }
        struct Case: Decodable {
            struct Input: Decodable { let hue: Double; let intensity: Double }
            let input: Input
            let accentRgba: [Int]
            let intensity: Double
            let coverage: Double
            let redMix: Double
            struct Stop: Decodable { let color: [Double]; let location: Double }
            let backgroundStops: [Stop]
            let borderSrgb: [Double]
        }
        let producer: Producer
        let cases: [Case]
    }
    let url = try #require(Bundle.module.url(forResource: "attention-color-cb89104", withExtension: "json", subdirectory: "Snapshots"))
    let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    #expect(fixture.producer.revision == "cb891040bb40fa5668a7ccb851681396620b4d11")
    #expect(fixture.cases.count == 30)
    for sample in fixture.cases {
        let style = BleeckerAttentionStyle(hue: sample.input.hue, intensity: sample.input.intensity)
        let rgb = [style.accent.red, style.accent.green, style.accent.blue, style.accent.alpha]
        #expect(rgb.map { Int(($0 * 255).rounded()) } == sample.accentRgba,
                "Producer accent differs at hue \(sample.input.hue), intensity \(sample.input.intensity)")
        // Match the recorded browser's legacy alpha parsing before mixing.
        // Decimal serialization/conversion precision is bounded to 1e-5;
        // the opaque accent above must also match exactly at eight bits.
        let nativePaints = style.stops + [style.border]
        let browserPaints = sample.backgroundStops.map(\.color) + [sample.borderSrgb]
        for (native, browser) in zip(nativePaints, browserPaints) {
            for (actual, expected) in zip([native.red, native.green, native.blue, native.alpha], browser) {
                #expect(abs(actual - expected) <= 0.00001,
                        "Producer paint differs at hue \(sample.input.hue), intensity \(sample.input.intensity)")
            }
        }
        #expect(sample.backgroundStops.map(\.location) == [0, style.middleStop, style.coverage])
        #expect(style.intensity == sample.intensity)
        #expect(abs(style.coverage - sample.coverage / 100) < 0.0000001)
        #expect(abs(style.redMix - sample.redMix / 100) < 0.0000001)
    }
}

@Test func attentionSurfaceRetainsCoverageAndPremultipliedPaint() {
    for (intensity, coverage, middle) in [(0.0, 0.24, 0.139), (5.0, 0.60, 0.348), (10.0, 0.96, 0.557)] {
        let style = BleeckerAttentionStyle(hue: 210, intensity: intensity)
        #expect(abs(style.coverage - coverage) < 0.0000001)
        #expect(abs(style.middleStop - middle) < 0.0000001)
        #expect(style.stops.count == 3)
        #expect(style.stops[2] == BleeckerAttentionRGBA(red: 17 / 255, green: 30 / 255, blue: 41 / 255, alpha: 240 / 255))
        let strength = floor(10 + intensity * 6.2 + 0.5) / 100
        #expect(abs(style.stops[0].alpha - (strength + (1 - strength) * (240 / 255))) < 0.0000001)
        let borderStrength = floor(12 + intensity * 2.4 + 0.5) / 100
        #expect(abs(style.border.alpha - (borderStrength + (1 - borderStrength) * (15 / 255))) < 0.0000001)
    }
}

@Test func attentionNormalizesInvalidAndWrappedInputsLikeTheProducer() {
    let invalid = BleeckerAttentionStyle(hue: .nan, intensity: .infinity)
    #expect(invalid.normalizedHue == 210)
    #expect(invalid.intensity == 0)
    #expect(invalid.accent == BleeckerAttentionStyle(hue: 210, intensity: 0).accent)
    #expect(BleeckerAttentionStyle(hue: -0.5, intensity: 0).normalizedHue == 0)
    #expect(BleeckerAttentionStyle(hue: -0.6, intensity: 0).normalizedHue == 359)
    #expect(BleeckerAttentionStyle(hue: 720.6, intensity: 0).normalizedHue == 1)
}

#if os(macOS)
@Test @MainActor func attentionDensitiesMeasureTheirActualContentInsets() {
    for density in BleeckerAttentionDensity.allCases {
        let host = NSHostingView(rootView: BleeckerAttentionSurface(hue: 210, intensity: 5, density: density) {
            Color.clear.frame(width: 100, height: 40)
        })
        let inset: CGFloat = density == .compact ? 17 : 21
        #expect(host.fittingSize == CGSize(width: 100 + inset * 2, height: 40 + inset * 2))
    }
}
#endif



#if os(macOS)
@Test @MainActor func attentionNativeGradientMatchesBrowserAtBothAspectRatios() throws {
    struct Fixture: Decodable {
        struct Producer: Decodable {
            struct Raster: Decodable { let file: String; let width: Int; let height: Int; let hue: Double; let intensity: Double }
            let rasters: [Raster]
        }
        let producer: Producer
    }
    let url = try #require(Bundle.module.url(forResource: "attention-color-cb89104", withExtension: "json", subdirectory: "Snapshots"))
    let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    #expect(fixture.producer.rasters.count == 2)
    for sample in fixture.producer.rasters {
        let referenceURL = try #require(Bundle.module.url(forResource: sample.file, withExtension: nil, subdirectory: "Snapshots"))
        let reference = try #require(NSBitmapImageRep(data: Data(contentsOf: referenceURL)))
        let content = BleeckerAttentionSurface(hue: sample.hue, intensity: sample.intensity) { Color.clear }
            .frame(width: CGFloat(sample.width), height: CGFloat(sample.height)).padding(80).background(Color.white)
        let renderer = ImageRenderer(content: content); renderer.scale = 1
        let native = try #require(renderer.cgImage)
        let referenceImage = try #require(reference.cgImage)
        #expect(native.width == referenceImage.width && native.height == referenceImage.height)
        let actualPixels = try attentionSRGBPixels(native)
        let expectedPixels = try attentionSRGBPixels(referenceImage)
        // Interior only: this checks actual gradient direction/interpolation.
        // One code value covers legacy alpha conversion, one native dithering.
        // Border antialiasing and exterior blur remain separate visual checks.
        for y in stride(from: 12, to: sample.height - 12, by: 19) {
            for x in stride(from: 12, to: sample.width - 12, by: 19) {
                let offset = ((y + 80) * native.width + x + 80) * 4
                let a = actualPixels[offset..<(offset + 3)]
                let b = expectedPixels[offset..<(offset + 3)]
                #expect(zip(a, b).allSatisfy { abs(Int($0) - Int($1)) <= 2 },
                        "Browser gradient differs at \(sample.file) \(x),\(y): native=\(a), browser=\(b)")
            }
        }
    }
}
#endif

#if os(macOS)
private func attentionSRGBPixels(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return bytes
    }
#endif
