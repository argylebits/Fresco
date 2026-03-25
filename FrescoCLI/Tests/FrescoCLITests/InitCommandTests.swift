import ArgumentParser
import Foundation
import Testing
@testable import FrescoCLI

@Suite(.serialized)
struct InitCommandTests {
    @Test func command_hasCorrectConfiguration() {
        #expect(InitCommand.configuration.commandName == "init")
    }

    @Test func command_parsesAllFlags() throws {
        let cmd = try InitCommand.parse([
            "--name", "Test",
            "--slug", "test",
            "--prompt", "a test prompt",
            "--schedule", "daily",
            "--schedule-hour", "8",
            "--defaults",
        ])
        #expect(cmd.name == "Test")
        #expect(cmd.slug == "test")
        #expect(cmd.prompt == "a test prompt")
        #expect(cmd.schedule == "daily")
        #expect(cmd.scheduleHour == 8)
        #expect(cmd.defaults == true)
    }

    @Test func command_parsesWithNoFlags() throws {
        let cmd = try InitCommand.parse([])
        #expect(cmd.name == nil)
        #expect(cmd.slug == nil)
        #expect(cmd.prompt == nil)
        #expect(cmd.schedule == nil)
        #expect(cmd.scheduleHour == nil)
        #expect(cmd.defaults == false)
    }

    @Test func run_doesNotWriteEnvFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            #expect(!FileManager.default.fileExists(atPath: dir + "/.env"))
        }
    }

    @Test func run_writesWorkflowFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let workflow = try String(contentsOfFile: dir + "/.github/workflows/fresco.yml", encoding: .utf8)
            #expect(workflow.contains("cron:"))
            #expect(workflow.contains("0 8 * * *"))
        }
    }

    @Test func run_createsGalleryFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let gallery = try String(contentsOfFile: dir + "/gallery.md", encoding: .utf8)
            #expect(gallery.contains("# Test Project Gallery"))
            #expect(gallery.contains("<!-- Fresco appends new entries below this line on each generation -->"))
        }
    }

    @Test func run_insertsMarkerInReadme() async throws {
        try await inTmpDir { dir in
            try "# Test Project\n".write(toFile: dir + "/README.md", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let readme = try String(contentsOfFile: dir + "/README.md", encoding: .utf8)
            #expect(readme.contains("<!-- Fresco image -->"))
        }
    }

    @Test func run_skipsExistingWorkflow() async throws {
        try await inTmpDir { dir in
            let workflowDir = dir + "/.github/workflows"
            try FileManager.default.createDirectory(atPath: workflowDir, withIntermediateDirectories: true)
            try "existing workflow".write(toFile: workflowDir + "/fresco.yml", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let workflow = try String(contentsOfFile: workflowDir + "/fresco.yml", encoding: .utf8)
            #expect(workflow == "existing workflow")
        }
    }

    @Test func run_createsGitignoreWithEnv_whenMissing() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let gitignore = try String(contentsOfFile: dir + "/.gitignore", encoding: .utf8)
            #expect(gitignore.contains(".env"))
        }
    }

    @Test func run_appendsEnvToGitignore_whenNotListed() async throws {
        try await inTmpDir { dir in
            try "node_modules/\n.DS_Store\n".write(toFile: dir + "/.gitignore", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let gitignore = try String(contentsOfFile: dir + "/.gitignore", encoding: .utf8)
            #expect(gitignore.contains(".env"))
            #expect(gitignore.contains("node_modules/"))
        }
    }

    @Test func run_skipsGitignore_whenEnvAlreadyListed() async throws {
        try await inTmpDir { dir in
            try ".env\nnode_modules/\n".write(toFile: dir + "/.gitignore", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let gitignore = try String(contentsOfFile: dir + "/.gitignore", encoding: .utf8)
            let envCount = gitignore.components(separatedBy: "\n").filter { $0.trimmingCharacters(in: .whitespaces) == ".env" }.count
            #expect(envCount == 1)
        }
    }

    // MARK: - Helpers

    private func makeCommand(extraFlags: [String] = []) throws -> InitCommand {
        var flags = [
            "--name", "Test Project",
            "--slug", "test-slug",
            "--prompt", "test prompt",
            "--schedule", "daily",
            "--schedule-hour", "8",
            "--defaults",
        ]
        flags.append(contentsOf: extraFlags)
        return try InitCommand.parse(flags)
    }

    private func inTmpDir(_ body: (String) async throws -> Void) async throws {
        let dir = NSTemporaryDirectory() + "fresco-init-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(dir)
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: dir)
        }
        try await body(dir)
    }
}
