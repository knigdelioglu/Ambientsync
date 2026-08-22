import Foundation

final class LaunchAgentService {
    private let launchAgentLabel: String
    private let launchAgentsDirectory: URL
    private let launchAgentURL: URL
    private let executablePath: String

    init(
        launchAgentLabel: String,
        launchAgentsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true),
        executableURL: URL? = Bundle.main.executableURL
    ) {
        self.launchAgentLabel = launchAgentLabel
        self.launchAgentsDirectory = launchAgentsDirectory
        self.launchAgentURL = launchAgentsDirectory.appendingPathComponent("\(launchAgentLabel).plist")
        self.executablePath = executableURL?.path ?? ""
    }

    func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func install() throws {
        try FileManager.default.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)

        guard !executablePath.isEmpty else {
            throw NSError(
                domain: "AmbientSync",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "app executable path unavailable"]
            )
        }

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>ProcessType</key>
            <string>Background</string>
        </dict>
        </plist>
        """

        guard let data = plist.data(using: .utf8) else {
            throw NSError(
                domain: "AmbientSync",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "failed to encode launch agent plist"]
            )
        }

        try data.write(to: launchAgentURL, options: .atomic)
    }

    func uninstall() throws {
        if FileManager.default.fileExists(atPath: launchAgentURL.path) {
            try FileManager.default.removeItem(at: launchAgentURL)
        }
    }
}
