import Foundation
import FrescoCore

struct WorkflowWriter: Sendable {
    func cronExpression(schedule: String, hour: Int) throws(FrescoError) -> String {
        guard (0...23).contains(hour) else {
            throw FrescoError.configurationError("Invalid schedule hour: \(hour). Must be 0-23.")
        }

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
            throw FrescoError.configurationError("Invalid schedule: \(schedule). Must be daily, weekly, monthly, quarterly, or annual.")
        }
    }

    func writeWorkflow(to path: String, schedule: String, scheduleHour: Int) throws {
        let cron = try cronExpression(schedule: schedule, hour: scheduleHour)
        let template = workflowTemplate(cron: cron)

        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
        }

        try template.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func workflowTemplate(cron: String) -> String {
        """
        name: Fresco Image Generation

        on:
          schedule:
            - cron: '\(cron)'
          workflow_dispatch:        # manual trigger from GitHub UI

        permissions:
          contents: write
          pull-requests: write

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

              - name: Create PR with gallery update
                run: |
                  git config user.name "github-actions[bot]"
                  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
                  git add gallery.md
                  if git diff --staged --quiet; then
                    echo "No gallery changes to commit."
                    exit 0
                  fi
                  DATE="$(date +%Y-%m-%d)"
                  BRANCH="fresco/gallery-${DATE}-${{ github.run_id }}"
                  git checkout -b "$BRANCH"
                  git commit -m "fresco: ${DATE}"
                  git push origin "$BRANCH"
                  gh pr create \
                    --title "fresco: ${DATE}" \
                    --body "Automated gallery update from Fresco image generation." \
                    --base main \
                    --head "$BRANCH"
                env:
                  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        """
    }
}
