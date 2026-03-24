import ArgumentParser
import Foundation

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new Fresco project"
    )

    @Option(name: .long, help: "Project display name")
    var name: String?

    @Option(name: .long, help: "Project slug (used in R2 paths and URLs)")
    var slug: String?

    @Option(name: .long, help: "Image generation prompt")
    var prompt: String?

    @Option(name: .long, help: "Generation schedule: daily, weekly, monthly, quarterly, annual")
    var schedule: String?

    @Option(name: .long, help: "UTC hour for generation (0-23)")
    var scheduleHour: Int?

    @Option(name: .long, help: "Gemini API key")
    var geminiKey: String?

    @Option(name: .long, help: "Cloudflare R2 account ID")
    var r2AccountId: String?

    @Option(name: .long, help: "R2 access key ID")
    var r2AccessKeyId: String?

    @Option(name: .long, help: "R2 secret access key")
    var r2SecretAccessKey: String?

    @Option(name: .long, help: "R2 bucket name")
    var r2Bucket: String?

    @Option(name: .long, help: "R2 public base URL")
    var r2PublicBaseUrl: String?

    @Flag(name: .long, help: "Use default/placeholder values for anything not provided")
    var defaults: Bool = false

    @Flag(name: .long, help: "Overwrite existing configuration")
    var force: Bool = false

    mutating func run() async throws {
        let envPath = ".env"
        if FileManager.default.fileExists(atPath: envPath) && !force {
            print(".env already exists. Use --force to overwrite.")
            throw ExitCode.failure
        }

        let resolvedName = name ?? resolve("Project name", default: "My Project")
        let resolvedSlug = slug ?? resolve("Project slug", default: "my-project")
        let resolvedPrompt = prompt ?? resolve("Image generation prompt", default: "A fresco like the ones you'd see in central Texas, tagged with graffiti art that says Fresco. 4:1.")
        let resolvedSchedule = schedule ?? resolve("Schedule (daily, weekly, monthly, quarterly, annual)", default: "daily")
        let resolvedScheduleHour = scheduleHour ?? resolveInt("Schedule hour (0-23 UTC)", default: 3)
        let resolvedGeminiKey = geminiKey ?? resolve("Gemini API key", default: "your-gemini-api-key")
        let resolvedR2AccountId = r2AccountId ?? resolve("R2 account ID", default: "your-cloudflare-account-id")
        let resolvedR2AccessKeyId = r2AccessKeyId ?? resolve("R2 access key ID", default: "your-r2-access-key-id")
        let resolvedR2SecretAccessKey = r2SecretAccessKey ?? resolve("R2 secret access key", default: "your-r2-secret-access-key")
        let resolvedR2Bucket = r2Bucket ?? resolve("R2 bucket name", default: "fresco-images")
        let resolvedR2PublicBaseUrl = r2PublicBaseUrl ?? resolve("R2 public base URL", default: "https://pub-xxxx.r2.dev")

        let envContent = """
            FRESCO_PROMPT="\(resolvedPrompt)"
            FRESCO_SLUG="\(resolvedSlug)"
            FRESCO_NAME="\(resolvedName)"
            FRESCO_SCHEDULE="\(resolvedSchedule)"
            FRESCO_SCHEDULE_HOUR="\(resolvedScheduleHour)"

            GEMINI_API_KEY="\(resolvedGeminiKey)"
            R2_ACCOUNT_ID="\(resolvedR2AccountId)"
            R2_ACCESS_KEY_ID="\(resolvedR2AccessKeyId)"
            R2_SECRET_ACCESS_KEY="\(resolvedR2SecretAccessKey)"
            R2_BUCKET="\(resolvedR2Bucket)"
            R2_PUBLIC_BASE_URL="\(resolvedR2PublicBaseUrl)"
            """

        try envContent.write(toFile: envPath, atomically: true, encoding: .utf8)
        print("Wrote .env")

        let workflowWriter = WorkflowWriter()
        let workflowPath = ".github/workflows/fresco.yml"
        if FileManager.default.fileExists(atPath: workflowPath) && !force {
            print("\(workflowPath) already exists. Skipping. Use --force to overwrite.")
        } else {
            try workflowWriter.writeWorkflow(to: workflowPath, schedule: resolvedSchedule, scheduleHour: resolvedScheduleHour)
            print("Wrote \(workflowPath)")
        }

        let todayURL = "\(resolvedR2PublicBaseUrl)/\(resolvedSlug)/today.jpg"
        let readmePath = "README.md"
        if FileManager.default.fileExists(atPath: readmePath) {
            let readmeUpdater = ReadmeUpdater()
            try readmeUpdater.insertImageURL(in: readmePath, imageURL: todayURL)
            print("Updated README.md with Fresco image")
        }

        let galleryPath = "gallery.md"
        if !FileManager.default.fileExists(atPath: galleryPath) {
            let galleryContent = """
                # \(resolvedName) Gallery

                <!-- Fresco appends new entries below this line on each generation -->
                """
            try galleryContent.write(toFile: galleryPath, atomically: true, encoding: .utf8)
            print("Created gallery.md")
        }

        setGitHubSecrets([
            "FRESCO_PROMPT": resolvedPrompt,
            "FRESCO_SLUG": resolvedSlug,
            "FRESCO_NAME": resolvedName,
            "FRESCO_SCHEDULE": resolvedSchedule,
            "FRESCO_SCHEDULE_HOUR": "\(resolvedScheduleHour)",
            "GEMINI_API_KEY": resolvedGeminiKey,
            "R2_ACCOUNT_ID": resolvedR2AccountId,
            "R2_ACCESS_KEY_ID": resolvedR2AccessKeyId,
            "R2_SECRET_ACCESS_KEY": resolvedR2SecretAccessKey,
            "R2_BUCKET": resolvedR2Bucket,
            "R2_PUBLIC_BASE_URL": resolvedR2PublicBaseUrl,
        ])

        print("\nFresco initialized!")

        if defaults {
            print("Run `fresco generate` to create your first image.")
        } else {
            print("Run `fresco generate` now? [y/N]: ", terminator: "")
            if let input = readLine(), input.lowercased() == "y" {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = ["fresco", "generate"]
                try process.run()
                process.waitUntilExit()
            }
        }
    }

    private func setGitHubSecrets(_ secrets: [String: String]) {
        let ghPath = "/usr/bin/env"
        for (key, value) in secrets.sorted(by: { $0.key < $1.key }) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ghPath)
            process.arguments = ["gh", "secret", "set", key, "--body", value]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    print("Set secret \(key)")
                } else {
                    print("Warning: could not set secret \(key) (is `gh` installed and authenticated?)")
                }
            } catch {
                print("Warning: could not set secret \(key) (is `gh` installed?)")
            }
        }
    }

    private func resolveInt(_ label: String, default defaultValue: Int) -> Int {
        if defaults {
            return defaultValue
        }
        print("\(label) [\(defaultValue)]: ", terminator: "")
        guard let input = readLine(), !input.isEmpty else {
            return defaultValue
        }
        return Int(input) ?? defaultValue
    }

    private func resolve(_ label: String, default defaultValue: String) -> String {
        if defaults {
            return defaultValue
        }
        print("\(label) [\(defaultValue)]: ", terminator: "")
        guard let input = readLine(), !input.isEmpty else {
            return defaultValue
        }
        return input
    }
}
