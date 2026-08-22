import Foundation

public enum HiDPIReportPaths {
    public static func projectRootURL(
        fileManager: FileManager = .default,
        currentDirectoryPath: String = FileManager.default.currentDirectoryPath
    ) -> URL {
        var candidate = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)

        while true {
            let packageURL = candidate.appendingPathComponent("Package.swift")
            if fileManager.fileExists(atPath: packageURL.path) {
                return candidate
            }

            let sourcesURL = candidate.appendingPathComponent("Sources/AmbientSync")
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: sourcesURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                return candidate
            }

            let parent = candidate.deletingLastPathComponent()
            if parent.path == candidate.path {
                break
            }
            candidate = parent
        }

        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/AmbientSync/Reports", isDirectory: true)
    }

    public static func reportURL(_ relativePath: String) -> URL {
        projectRootURL().appendingPathComponent(relativePath)
    }

    public static func write(_ content: String, to relativePath: String) throws -> URL {
        let url = reportURL(relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
