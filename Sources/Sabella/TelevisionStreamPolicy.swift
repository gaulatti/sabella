import Foundation

enum SabellaTVPlaybackEngine: Equatable {
    case native
    case ffmpeg
}

enum SabellaTVPlaybackEnginePolicy {
    static func engine(
        for url: URL,
        contentType: String? = nil,
        leadingBytes: Data = Data()
    ) -> SabellaTVPlaybackEngine? {
        let scheme = url.scheme?.lowercased()
        if scheme == "rtmp" || scheme == "rtmps" {
            return .ffmpeg
        }

        let normalizedContentType = contentType?
            .split(separator: ";", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let normalizedContentType {
            if normalizedContentType == "video/mp2t"
                || normalizedContentType.contains("mpegts")
                || normalizedContentType.contains("dash+xml") {
                return .ffmpeg
            }

            if normalizedContentType.contains("mpegurl")
                || normalizedContentType.hasPrefix("audio/")
                || normalizedContentType == "video/mp4"
                || normalizedContentType == "video/quicktime" {
                return .native
            }
        }

        if isMPEGTransportStream(leadingBytes) {
            return .ffmpeg
        }

        if leadingBytes.starts(with: Data("#EXTM3U".utf8)) {
            return .native
        }

        switch url.pathExtension.lowercased() {
        case "ts", "m2ts", "mpegts", "mpd":
            return .ffmpeg
        case "m3u", "m3u8", "mp4", "mov", "m4a", "mp3", "aac":
            return .native
        default:
            return nil
        }
    }

    private static func isMPEGTransportStream(_ data: Data) -> Bool {
        let packetLength = 188
        let requiredPackets = 3
        guard data.count >= packetLength * (requiredPackets - 1) + 1 else { return false }

        let bytes = [UInt8](data)
        let searchLimit = min(packetLength, bytes.count)
        for offset in 0..<searchLimit {
            guard offset + packetLength * (requiredPackets - 1) < bytes.count else { break }
            if (0..<requiredPackets).allSatisfy({ bytes[offset + packetLength * $0] == 0x47 }) {
                return true
            }
        }
        return false
    }
}
