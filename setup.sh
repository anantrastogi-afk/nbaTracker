#!/bin/bash
set -e

echo "🏀 NBA Tracker — Project Setup"
echo "==============================="

# Install XcodeGen if not present
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "❌ Homebrew not found. Install it from https://brew.sh then re-run this script."
        exit 1
    fi
fi

echo "⚙️  Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Done! Open NBATracker.xcodeproj in Xcode to build and run."
echo ""
echo "   open NBATracker.xcodeproj"
echo ""
