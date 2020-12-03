#!/bin/bash

# **** Update me when new Xcode versions are released! ****
PLATFORM="platform=iOS Simulator,OS=14.0,name=iPhone 11 Pro Max"
SDK="iphonesimulator"


# It is pitch black.
set -e
function trap_handler() {
    echo -e "\n\nOh no! You walked directly into the slavering fangs of a lurking grue!"
    echo "**** You have died ****"
    exit 255
}
trap trap_handler INT TERM EXIT


MODE="$1"

if [ "$MODE" = "build" ]; then
    echo "Building libPhoneNumber."
    xcodebuild \
        -project libPhoneNumber.xcodeproj \
        -scheme libPhoneNumber \
        -sdk "$SDK" \
        -destination "$PLATFORM" \
        build test
    trap - EXIT
    exit 0
fi

if [ "$MODE" = "examples" ]; then
    echo "Building and testing all libPhoneNumber examples."

    for example in examples/*/; do
        echo "Building $example."
        xcodebuild \
            -project "${example}Sample.xcodeproj" \
            -scheme Sample \
            -sdk "$SDK" \
            -destination "$PLATFORM" \
            build
    done
    trap - EXIT
    exit 0
fi

echo "Unrecognised mode '$MODE'."
