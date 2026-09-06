import CoreText
import Foundation

/// Registers the typefaces shipped with Sabella for the lifetime of the process.
public enum SabellaFonts {
    public static let postScriptNames = [
        "EncodeSans-Th",
        "EncodeSans-XLt",
        "EncodeSans-Lt",
        "EncodeSans-Regular",
        "EncodeSans-Md",
        "EncodeSans-SmBold",
        "EncodeSans-Bold",
        "EncodeSans-XBd",
        "EncodeSans-Black",
        "LibreFranklin-Thin",
        "LibreFranklin-ExtraLight",
        "LibreFranklin-Light",
        "LibreFranklin-Regular",
        "LibreFranklin-Medium",
        "LibreFranklin-SemiBold",
        "LibreFranklin-Bold",
        "LibreFranklin-ExtraBold",
        "LibreFranklin-Black",
    ]

    private static let resourceNames = [
        "EncodeSans-Thin",
        "EncodeSans-ExtraLight",
        "EncodeSans-Light",
        "EncodeSans-Regular",
        "EncodeSans-Medium",
        "EncodeSans-SemiBold",
        "EncodeSans-Bold",
        "EncodeSans-ExtraBold",
        "EncodeSans-Black",
        "LibreFranklin-Thin",
        "LibreFranklin-ExtraLight",
        "LibreFranklin-Light",
        "LibreFranklin-Regular",
        "LibreFranklin-Medium",
        "LibreFranklin-SemiBold",
        "LibreFranklin-Bold",
        "LibreFranklin-ExtraBold",
        "LibreFranklin-Black",
    ]

    private static let registration: Void = {
        for resource in resourceNames {
            guard let url = Bundle.module.url(
                forResource: resource,
                withExtension: "ttf",
                subdirectory: "Fonts"
            ) else {
                preconditionFailure("Sabella font resource is missing: Fonts/\(resource).ttf")
            }

            var registrationError: Unmanaged<CFError>?
            guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError) else {
                let error = registrationError?.takeRetainedValue()
                if error.map(CFErrorGetCode) == CTFontManagerError.alreadyRegistered.rawValue {
                    continue
                }
                preconditionFailure("Sabella could not register \(resource).ttf: \(String(describing: error))")
            }
        }
    }()

    /// Registers the bundled fonts. Sabella fails fast if its packaged resources are incomplete.
    public static func register() {
        _ = registration
    }

    /// Reports whether Core Text resolves the requested bundled face without substitution.
    public static func isRegistered(postScriptName: String) -> Bool {
        register()
        let font = CTFontCreateWithName(postScriptName as CFString, 16, nil)
        return CTFontCopyPostScriptName(font) as String == postScriptName
    }
}
