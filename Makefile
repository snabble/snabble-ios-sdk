.PHONY: test test-network test-core test-phoneauth packages-update packages-sync packages-check

WORKSPACE = .swiftpm/xcode/package.xcworkspace
SCHEME    = Snabble-Package
DESTINATION = platform=iOS Simulator,name=iPhone 18 Pro,OS=latest

test:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' test

test-network:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' test \
		-only-testing SnabbleNetworkTests

test-core:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' test \
		-only-testing SnabbleCoreTests

test-phoneauth:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' test \
		-only-testing SnabblePhoneAuthTests

# Update all dependencies and propagate the pins to the workspace and example projects
packages-update:
	scripts/packages.sh update

# Propagate the current root pins without updating
packages-sync:
	scripts/packages.sh sync

# Fail if any Package.resolved differs from the root Package.resolved
packages-check:
	scripts/packages.sh check
