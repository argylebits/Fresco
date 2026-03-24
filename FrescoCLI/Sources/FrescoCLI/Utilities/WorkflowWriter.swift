import Foundation

struct WorkflowWriter: Sendable {
    func cronExpression(schedule: String, hour: Int) -> String {
        switch schedule {
        case "daily":
            return "0 \(hour) * * *"
        case "weekly":
            return "0 \(hour) * * 1"
        case "monthly":
            return "0 \(hour) 1 * *"
        case "quarterly":
            return "0 \(hour) 1 1,4,7,10 *"
        case "annual":
            return "0 \(hour) 1 1 *"
        default:
            return "0 \(hour) * * *"
        }
    }

    func writeWorkflow(to path: String, schedule: String, scheduleHour: Int) throws {
        let cron = cronExpression(schedule: schedule, hour: scheduleHour)
        let template = workflowTemplate(cron: cron)

        let directory = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )

        try template.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func workflowTemplate(cron: String) -> String {
        """
        name: Fresco Image Generation

        on:
          schedule:
            - cron: '\(cron)'
          workflow_dispatch:

        jobs:
          generate:
            runs-on: macos-latest

            steps:
              - uses: actions/checkout@v4
                with:
                  token: ${{ secrets.GITHUB_TOKEN }}

              - name: Install Fresco
                run: brew install argylebits/fresco

              - name: Generate image
                run: fresco generate
                env:
                  FRESCO_PROMPT:          ${{ secrets.FRESCO_PROMPT }}
                  FRESCO_SLUG:            ${{ secrets.FRESCO_SLUG }}
                  FRESCO_NAME:            ${{ secrets.FRESCO_NAME }}
                  FRESCO_SCHEDULE:        ${{ secrets.FRESCO_SCHEDULE }}
                  FRESCO_SCHEDULE_HOUR:   ${{ secrets.FRESCO_SCHEDULE_HOUR }}
                  GEMINI_API_KEY:        ${{ secrets.GEMINI_API_KEY }}
                  R2_ACCOUNT_ID:         ${{ secrets.R2_ACCOUNT_ID }}
                  R2_ACCESS_KEY_ID:      ${{ secrets.R2_ACCESS_KEY_ID }}
                  R2_SECRET_ACCESS_KEY:  ${{ secrets.R2_SECRET_ACCESS_KEY }}
                  R2_BUCKET:             ${{ secrets.R2_BUCKET }}
                  R2_PUBLIC_BASE_URL:    ${{ secrets.R2_PUBLIC_BASE_URL }}

              - name: Commit gallery update
                run: |
                  git config user.name "Fresco"
                  git config user.email "fresco@argylebits.com"
                  git add gallery.md
                  git diff --staged --quiet || git commit -m "fresco: $(date +%Y-%m-%d)"
                  git push
        """
    }
}
