import Danger

let danger = Danger()
let allSourceFiles = danger.git.modifiedFiles + danger.git.createdFiles
let changelogChanged = allSourceFiles.contains("CHANGELOG.md")

if !changelogChanged {
  warn("No CHANGELOG entry added.")
}
