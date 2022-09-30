import Danger

let danger = Danger()
let allSourceFiles = danger.git.modifiedFiles + danger.git.createdFiles
let changelogChanged = allSourceFiles.contains("documentation/Changelog.md")

if !changelogChanged {
  warn("No CHANGELOG entry added.")
}

SwiftLint.lint(inline: true)
