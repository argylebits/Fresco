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

    @Flag(name: .long, help: "Use default/placeholder values for anything not provided")
    var defaults: Bool = false

    mutating func run() async throws {
        let resolvedName = name ?? resolve("Project name", default: "My Project")
        let resolvedSchedule = schedule ?? resolve("Schedule (daily, weekly, monthly, quarterly, annual)", default: "daily")
        let resolvedScheduleHour = scheduleHour ?? resolveInt("Schedule hour (0-23 UTC)", default: 3)

        // Validate before writing any files
        let workflowWriter = WorkflowWriter()
        _ = try workflowWriter.cronExpression(schedule: resolvedSchedule, hour: resolvedScheduleHour)

        // Ensure .env is in .gitignore
        ensureGitignoreContainsEnv()

        let workflowPath = ".github/workflows/fresco.yml"
        if FileManager.default.fileExists(atPath: workflowPath) {
            print("\(workflowPath) already exists. Skipping.")
        } else {
            try workflowWriter.writeWorkflow(to: workflowPath, schedule: resolvedSchedule, scheduleHour: resolvedScheduleHour)
            print("Wrote \(workflowPath)")
        }

        let readmePath = "README.md"
        if FileManager.default.fileExists(atPath: readmePath) {
            try ReadmeUpdater().insertMarker(in: readmePath)
            print("Added Fresco marker to README.md")
        }

        let galleryPath = "gallery.md"
        if !FileManager.default.fileExists(atPath: galleryPath) {
            let galleryContent = """
                # \(resolvedName) Gallery

                \(GalleryWriter.marker)
                """
            try galleryContent.write(toFile: galleryPath, atomically: true, encoding: .utf8)
            print("Created gallery.md")
        }

        print("\nFresco initialized!")
        print("Copy fresco.template.env to .env and fill in your values.")
        print("Add your secrets as GitHub Actions repository secrets for scheduled runs.")
        print("Run `fresco generate` to create your first image.")
    }

    private func ensureGitignoreContainsEnv() {
        let gitignorePath = ".gitignore"
        if FileManager.default.fileExists(atPath: gitignorePath) {
            guard let content = try? String(contentsOfFile: gitignorePath, encoding: .utf8) else { return }
            let lines = content.components(separatedBy: "\n")
            let hasEnv = lines.contains { $0.trimmingCharacters(in: .whitespaces) == ".env" }
            if !hasEnv {
                let append = content.hasSuffix("\n") ? ".env\n" : "\n.env\n"
                try? (content + append).write(toFile: gitignorePath, atomically: true, encoding: .utf8)
            }
        } else {
            try? ".env\n".write(toFile: gitignorePath, atomically: true, encoding: .utf8)
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
