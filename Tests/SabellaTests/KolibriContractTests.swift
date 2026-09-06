import Foundation
import Testing
@testable import Sabella

private enum KolibriClassification: String, CaseIterable {
    case exact
    case nativeAdaptation = "native-adaptation"
    case platformException = "platform-exception"
    case unsupported
    case producerDefect = "producer-defect"
}

private enum KolibriPlatform: String, CaseIterable {
    case macOS
    case iOS
    case tvOS
}

private enum KolibriInput: String {
    case accessibilityActivate = "accessibility-activate"
    case focusMove = "focus-move"
    case keyboardReturn = "keyboard-return"
    case pointerClick = "pointer-click"
    case remoteSelect = "remote-select"
    case touchTap = "touch-tap"
}

private enum KolibriProofError: Error {
    case incompatibleFixture(String)
}

private struct KolibriMetadata: Decodable {
    let compatibleSchemaVersions: String
    let releaseVersion: String
    let schemaVersion: String
    let sourceRevision: String
}

private struct KolibriEvent: Decodable {
    let name: String
}

private struct KolibriAction: Decodable {
    let id: String
    let type: String
}

private struct KolibriNode: Decodable {
    let children: [KolibriNode]?
    let element: String?
    let id: String
    let part: String?
    let text: String?
    let type: String
}

private struct KolibriComponent: Decodable {
    let actions: [KolibriAction]
    let assets: [EmptyValue]
    let behaviors: [EmptyValue]
    let events: [KolibriEvent]
    let id: String
    let kind: String
    let name: String
    let tree: [KolibriNode]

    private enum CodingKeys: String, CodingKey {
        case actions, assets, behaviors, events, id, kind, name, tree
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actions = try container.decode([KolibriAction].self, forKey: .actions)
        assets = try container.decode([EmptyValue].self, forKey: .assets)
        behaviors = try container.decode([EmptyValue].self, forKey: .behaviors)
        events = try container.decode([KolibriEvent].self, forKey: .events)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(String.self, forKey: .kind)
        name = try container.decode(String.self, forKey: .name)
        tree = try container.decode([KolibriNode].self, forKey: .tree)
    }
}

private struct EmptyValue: Decodable {}

private struct KolibriDocument: Decodable {
    let components: [KolibriComponent]
    let entrypoints: [String]
    let metadata: KolibriMetadata
}

private struct KolibriMapping {
    let classification: KolibriClassification
    let id: String
    let native: String
    let source: String

    var line: String {
        "mapping: \(id) | \(classification.rawValue) | \(source) -> \(native)"
    }
}

private struct KolibriState {
    let classification: KolibriClassification
    let id: String
    let native: String

    var line: String {
        "state: \(id) | \(classification.rawValue) | \(native)"
    }
}

private struct KolibriCapability {
    let classification: KolibriClassification
    let id: String
    let native: String

    var line: String {
        "capability: \(id) | \(classification.rawValue) | \(native)"
    }
}

private struct KolibriPrimaryButtonSnapshot {
    let activationInputs: Set<KolibriInput>
    let capabilities: [KolibriCapability]
    let mappings: [KolibriMapping]
    let platform: KolibriPlatform
    let publicAPI: String
    let states: [KolibriState]

    func activates(_ input: KolibriInput, enabled: Bool = true) -> Bool {
        enabled && activationInputs.contains(input)
    }

    var rendered: String {
        var lines = [
            "adapter-version: 1",
            "bundle-release: 0.1.0",
            "bundle-schema: 1.0.0",
            "component: button.primary",
            "platform: \(platform.rawValue)",
            "public-api: \(publicAPI)",
            "activation-inputs: \(activationInputs.map(\.rawValue).sorted().joined(separator: ", "))",
        ]
        lines.append(contentsOf: mappings.sorted { $0.id < $1.id }.map(\.line))
        lines.append(contentsOf: states.sorted { $0.id < $1.id }.map(\.line))
        lines.append(contentsOf: capabilities.sorted { $0.id < $1.id }.map(\.line))
        return lines.joined(separator: "\n") + "\n"
    }
}

private enum KolibriPrimaryButtonAdapter {
    static func validate(_ document: KolibriDocument) throws -> KolibriComponent {
        guard document.metadata.releaseVersion == "0.1.0",
              document.metadata.schemaVersion == "1.0.0",
              document.metadata.compatibleSchemaVersions == ">=1.0.0 <2.0.0",
              document.metadata.sourceRevision == "24e6905a0a6b9e6dae08b0832781b0f06f8c0b5f" else {
            throw KolibriProofError.incompatibleFixture("metadata")
        }
        guard document.entrypoints == ["button.primary"],
              document.components.count == 1,
              let component = document.components.first,
              component.id == "button.primary",
              component.name == "PrimaryButton",
              component.kind == "atom" else {
            throw KolibriProofError.incompatibleFixture("component")
        }
        guard component.events.map(\.name) == ["press"],
              component.actions.count == 1,
              component.actions.first?.id == "submit",
              component.actions.first?.type == "emit",
              component.assets.isEmpty,
              component.behaviors.isEmpty else {
            throw KolibriProofError.incompatibleFixture("interaction")
        }
        guard component.tree.count == 1,
              let root = component.tree.first,
              root.id == "button",
              root.type == "element",
              root.element == "button",
              root.part == "root",
              root.children?.count == 1,
              let label = root.children?.first,
              label.id == "label",
              label.type == "element",
              label.element == "span",
              label.part == "label",
              label.text == "Continue" else {
            throw KolibriProofError.incompatibleFixture("semantic-parts")
        }
        return component
    }

    static func snapshot(document: KolibriDocument, platform: KolibriPlatform) throws -> KolibriPrimaryButtonSnapshot {
        _ = try validate(document)

        let mappings = [
            KolibriMapping(classification: .exact, id: "action.submit", native: "action closure", source: "emit"),
            KolibriMapping(classification: .exact, id: "assets", native: "no assets", source: "empty"),
            KolibriMapping(classification: .exact, id: "behaviors", native: "no ordered behavior", source: "empty"),
            KolibriMapping(classification: .nativeAdaptation, id: "event.press", native: activation(for: platform), source: "press"),
            KolibriMapping(classification: .nativeAdaptation, id: "part.label", native: "SwiftUI.Text", source: "span"),
            KolibriMapping(classification: .nativeAdaptation, id: "part.root", native: nativeRoot(for: platform), source: "button"),
        ]
        let states = [
            KolibriState(classification: .nativeAdaptation, id: "disabled", native: "SwiftUI disabled environment"),
            KolibriState(classification: .nativeAdaptation, id: "enabled", native: "SwiftUI Button default"),
            KolibriState(classification: .platformException, id: "focused", native: focus(for: platform)),
            KolibriState(classification: platform == .tvOS ? .unsupported : .nativeAdaptation, id: "loading", native: loading(for: platform)),
            KolibriState(classification: .nativeAdaptation, id: "pressed", native: "ButtonStyle.Configuration.isPressed"),
        ]
        let capabilities = [
            KolibriCapability(classification: .nativeAdaptation, id: "accessibility", native: "native Button role, label, activation, and disabled state"),
            KolibriCapability(classification: platform == .tvOS ? .platformException : .nativeAdaptation, id: "appearance", native: appearance(for: platform)),
            KolibriCapability(classification: .unsupported, id: "dynamic-type", native: "fixed custom font size; catalog exposure only, no scaling claim"),
            KolibriCapability(classification: .producerDefect, id: "manifest.appearance", native: "field absent from schema 1.0.0"),
            KolibriCapability(classification: .producerDefect, id: "manifest.responsive", native: "field absent from schema 1.0.0"),
            KolibriCapability(classification: .producerDefect, id: "manifest.states", native: "field absent from schema 1.0.0"),
            KolibriCapability(classification: .producerDefect, id: "manifest.tokens", native: "field absent from schema 1.0.0"),
            KolibriCapability(classification: .platformException, id: "responsive-layout", native: responsive(for: platform)),
        ]

        return KolibriPrimaryButtonSnapshot(
            activationInputs: inputs(for: platform),
            capabilities: capabilities,
            mappings: mappings,
            platform: platform,
            publicAPI: publicAPI(for: platform),
            states: states
        )
    }

    private static func activation(for platform: KolibriPlatform) -> String {
        switch platform {
        case .macOS: "native pointer, Return, Space, or accessibility activation"
        case .iOS: "native touch, keyboard, Switch Control, or accessibility activation"
        case .tvOS: "native remote Select or accessibility activation"
        }
    }

    private static func appearance(for platform: KolibriPlatform) -> String {
        switch platform {
        case .macOS, .iOS: "Sabella semantic light and dark palettes"
        case .tvOS: "television catalog intentionally dark"
        }
    }

    private static func focus(for platform: KolibriPlatform) -> String {
        switch platform {
        case .macOS: "native keyboard focus"
        case .iOS: "native full-keyboard and accessibility focus"
        case .tvOS: "native directional focus with visible Sabella focus treatment"
        }
    }

    private static func inputs(for platform: KolibriPlatform) -> Set<KolibriInput> {
        switch platform {
        case .macOS: [.accessibilityActivate, .keyboardReturn, .pointerClick]
        case .iOS: [.accessibilityActivate, .keyboardReturn, .touchTap]
        case .tvOS: [.accessibilityActivate, .remoteSelect]
        }
    }

    private static func loading(for platform: KolibriPlatform) -> String {
        platform == .tvOS ? "no loading state on SabellaTVPrimaryButtonStyle" : "BleeckerButton loading flag"
    }

    private static func nativeRoot(for platform: KolibriPlatform) -> String {
        platform == .tvOS ? "SwiftUI.Button + SabellaTVPrimaryButtonStyle" : "BleeckerButton + BleeckerButtonStyle.primary"
    }

    private static func publicAPI(for platform: KolibriPlatform) -> String {
        platform == .tvOS ? "Button.buttonStyle(SabellaTVPrimaryButtonStyle())" : "BleeckerButton(variant: .primary)"
    }

    private static func responsive(for platform: KolibriPlatform) -> String {
        switch platform {
        case .macOS: "container-owned native layout"
        case .iOS: "container-owned compact or regular native layout"
        case .tvOS: "ten-foot spacing and focus target"
        }
    }
}

private func repositoryRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private func pinnedDocument() throws -> KolibriDocument {
    let fixture = repositoryRoot()
        .appendingPathComponent("Tests/Fixtures/Kolibri/0.1.0/fixtures/static-component.json")
    return try JSONDecoder().decode(KolibriDocument.self, from: Data(contentsOf: fixture))
}

@Test func pinnedKolibriPrimaryButtonFixtureValidates() throws {
    let document = try pinnedDocument()
    let component = try KolibriPrimaryButtonAdapter.validate(document)

    #expect(component.id == "button.primary")
    #expect(component.tree.first?.part == "root")
    #expect(component.tree.first?.children?.first?.part == "label")
}

@Test func kolibriPrimaryButtonSnapshotsAreDeterministicAcrossApplePlatforms() throws {
    let document = try pinnedDocument()
    let snapshots = repositoryRoot().appendingPathComponent("Tests/SabellaTests/Snapshots/KolibriPrimaryButton")

    for platform in KolibriPlatform.allCases {
        let first = try KolibriPrimaryButtonAdapter.snapshot(document: document, platform: platform).rendered
        let second = try KolibriPrimaryButtonAdapter.snapshot(document: document, platform: platform).rendered
        let expected = try String(
            contentsOf: snapshots.appendingPathComponent("\(platform.rawValue).snapshot"),
            encoding: .utf8
        )

        #expect(first == second)
        #expect(first == expected)
    }
}

@Test func kolibriPrimaryButtonRejectsUnexplainedContractDrift() throws {
    let fixture = repositoryRoot()
        .appendingPathComponent("Tests/Fixtures/Kolibri/0.1.0/fixtures/static-component.json")
    var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: fixture)) as? [String: Any])
    var components = try #require(object["components"] as? [[String: Any]])
    components[0]["id"] = "button.renamed"
    object["components"] = components
    let changed = try JSONSerialization.data(withJSONObject: object)
    let document = try JSONDecoder().decode(KolibriDocument.self, from: changed)

    #expect(throws: KolibriProofError.self) {
        _ = try KolibriPrimaryButtonAdapter.validate(document)
    }
}

@Test func tvOSPrimaryButtonMappingOwnsRemoteFocusAndAccessibility() throws {
    let snapshot = try KolibriPrimaryButtonAdapter.snapshot(document: pinnedDocument(), platform: .tvOS)

    #expect(snapshot.activates(.remoteSelect))
    #expect(snapshot.activates(.accessibilityActivate))
    #expect(!snapshot.activates(.focusMove))
    #expect(!snapshot.activates(.touchTap))
    #expect(!snapshot.activates(.remoteSelect, enabled: false))
    #expect(snapshot.states.contains { $0.id == "focused" && $0.classification == .platformException })
    #expect(snapshot.capabilities.contains { $0.id == "accessibility" && $0.classification == .nativeAdaptation })
    #expect(snapshot.capabilities.contains { $0.id == "dynamic-type" && $0.classification == .unsupported })
}

@Test func kolibriPrimaryButtonMappingsHaveNoUnclassifiedStateOrPart() throws {
    for platform in KolibriPlatform.allCases {
        let snapshot = try KolibriPrimaryButtonAdapter.snapshot(document: pinnedDocument(), platform: platform)
        #expect(Set(snapshot.mappings.map(\.classification)).isSubset(of: Set(KolibriClassification.allCases)))
        #expect(Set(snapshot.states.map(\.classification)).isSubset(of: Set(KolibriClassification.allCases)))
        #expect(snapshot.mappings.filter { $0.id.hasPrefix("part.") }.map(\.id).sorted() == ["part.label", "part.root"])
        #expect(snapshot.states.map(\.id).sorted() == ["disabled", "enabled", "focused", "loading", "pressed"])
    }
}

@Test func sabellaNativeButtonSourcesBackTheContractSnapshots() throws {
    let root = repositoryRoot()
    let buttons = try String(contentsOf: root.appendingPathComponent("Sources/Sabella/Buttons.swift"), encoding: .utf8)
    let television = try String(contentsOf: root.appendingPathComponent("Sources/Sabella/Television.swift"), encoding: .utf8)

    #expect(buttons.contains("public struct BleeckerButton<Label: View>: View"))
    #expect(buttons.contains("Button(action: action)"))
    #expect(buttons.contains(".buttonStyle(BleeckerButtonStyle(variant, size: size))"))
    #expect(buttons.contains(".disabled(loading)"))
    #expect(buttons.contains("configuration.isPressed"))
    #expect(buttons.contains(".font(BleeckerTypography.primary(fontSize, weight: .medium))"))
    #expect(television.contains("public struct SabellaTVPrimaryButtonStyle: ButtonStyle"))
    #expect(television.contains("@Environment(\\.isFocused) private var focused"))
    #expect(television.contains("configuration.isPressed"))
    #expect(television.contains(".font(BleeckerTypography.primary(24, weight: .semibold))"))
}
