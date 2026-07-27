.PHONY: test test-network test-core test-phoneauth

WORKSPACE = .swiftpm/xcode/package.xcworkspace
SCHEME    = Snabble-Package
DESTINATION = platform=iOS Simulator,name=iPhone 17 Pro,OS=latest

test:
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' test

test-network:
	xcodebuild -workspace $(WORKSPACE) -scheme Snabble-Package \
		-destination '$(DESTINATION)' test \
		-only-testing SnabbleNetworkTests

test-core:
	xcodebuild -workspace $(WORKSPACE) -scheme Snabble-Package \
		-destination '$(DESTINATION)' test \
		-only-testing SnabbleCoreTests

test-phoneauth:
	xcodebuild -workspace $(WORKSPACE) -scheme Snabble-Package \
		-destination '$(DESTINATION)' test \
		-only-testing SnabblePhoneAuthTests
