import Foundation
import SwiftUI

/// Platform-neutral inputs from Bleecker cb891040's attention-color.ts.
/// OKLab conversion and premultiplied interpolation follow CSS Color 4:
/// https://www.w3.org/TR/css-color-4/#color-conversion-code
struct BleeckerAttentionRGBA: Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }

    static func hsl(hue: Double, saturation: Double, lightness: Double) -> Self {
        let sector = hue / 60
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let secondary = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let base = lightness - chroma / 2
        let rgb: (Double, Double, Double) = switch Int(sector) {
        case 0: (chroma, secondary, 0)
        case 1: (secondary, chroma, 0)
        case 2: (0, chroma, secondary)
        case 3: (0, secondary, chroma)
        case 4: (secondary, 0, chroma)
        default: (chroma, 0, secondary)
        }
        return Self(red: rgb.0 + base, green: rgb.1 + base, blue: rgb.2 + base)
    }

    private var lab: SIMD3<Double> {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let r = linear(red), g = linear(green), b = linear(blue)
        let l = cbrt(0.4122214708*r + 0.5363325363*g + 0.0514459929*b)
        let m = cbrt(0.2119034982*r + 0.6806995451*g + 0.1073969566*b)
        let s = cbrt(0.0883024619*r + 0.2817188376*g + 0.6299787005*b)
        return SIMD3(0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
                     1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
                     0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
    }

    private init(lab: SIMD3<Double>, alpha: Double) {
        let l = pow(lab.x + 0.3963377774*lab.y + 0.2158037573*lab.z, 3)
        let m = pow(lab.x - 0.1055613458*lab.y - 0.0638541728*lab.z, 3)
        let s = pow(lab.x - 0.0894841775*lab.y - 1.2914855480*lab.z, 3)
        func encoded(_ value: Double) -> Double {
            value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
        }
        self.red = encoded(4.0767416621*l - 3.3077115913*m + 0.2309699292*s)
        self.green = encoded(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s)
        self.blue = encoded(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
        self.alpha = alpha
    }

    static func mix(_ first: Self, _ second: Self, firstWeight: Double) -> Self {
        let a = first.alpha * firstWeight
        let b = second.alpha * (1 - firstWeight)
        let alpha = a + b
        return Self(lab: (first.lab * a + second.lab * b) / alpha, alpha: alpha)
    }

    var luminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    func label(on background: Self) -> Self {
        func contrast(_ color: Self) -> Double {
            (max(color.luminance, background.luminance) + 0.05) /
                (min(color.luminance, background.luminance) + 0.05)
        }
        // Quantize before checking: the chosen 8-bit paint itself must pass.
        func shifted(_ amount: Double, toward destination: Double) -> Self {
            func channel(_ value: Double) -> Double {
                (min(1, max(0, value * (1 - amount) + destination * amount)) * 255).rounded() / 255
            }
            return Self(red: channel(red), green: channel(green), blue: channel(blue))
        }
        let original = shifted(0, toward: 0)
        if contrast(original) >= 4.5 { return original }
        let destination = contrast(Self(red: 1, green: 1, blue: 1)) >
            contrast(Self(red: 0, green: 0, blue: 0)) ? 1.0 : 0.0
        var low = 0.0, high = 1.0
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if contrast(shifted(middle, toward: destination)) >= 4.5 { high = middle } else { low = middle }
        }
        return shifted(high, toward: destination)
    }
}

struct BleeckerAttentionStyle {
    let normalizedHue: Double
    let intensity: Double
    let redMix: Double
    let coverage: Double
    let middleStop: Double
    let accent: BleeckerAttentionRGBA
    let stops: [BleeckerAttentionRGBA]
    let border: BleeckerAttentionRGBA

    init(hue: Double, intensity rawIntensity: Double) {
        let rounded = floor((hue.isFinite ? hue : 210) + 0.5)
        normalizedHue = (rounded.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        intensity = min(10, max(0, rawIntensity.isFinite ? rawIntensity : 0))
        redMix = floor(intensity * 10 + 0.5) / 100
        coverage = (24 + intensity * 7.2).rounded(toPlaces: 1) / 100
        middleStop = ((24 + intensity * 7.2) * 0.58).rounded(toPlaces: 1) / 100
        accent = .mix(.hsl(hue: normalizedHue, saturation: 0.66, lightness: 0.52),
                      .hsl(hue: 6, saturation: 0.78, lightness: 0.56), firstWeight: 1 - redMix)
        // Pinned Chrome reference parses authored legacy rgba() alpha as
        // eight-bit values. Normalize only those two source operands, before
        // mixing; preserve precision in every intermediate native color.
        let base = BleeckerAttentionRGBA(red: 17 / 255, green: 30 / 255, blue: 41 / 255, alpha: (0.94 * 255).rounded() / 255)
        let strength = floor(10 + intensity * 6.2 + 0.5)
        stops = [.mix(accent, base, firstWeight: strength / 100),
                 .mix(accent, base, firstWeight: floor(strength * 0.66 + 0.5) / 100), base]
        border = .mix(accent, .init(red: 1, green: 1, blue: 1, alpha: (0.06 * 255).rounded() / 255),
                      firstWeight: floor(12 + intensity * 2.4 + 0.5) / 100)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
