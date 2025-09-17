#!/bin/bash

echo "WillingTree Flutter Setup Script"
echo "================================"

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    echo "✓ Flutter is already installed"
    flutter --version
else
    echo "Flutter needs to be installed"
    echo ""
    echo "Please install Flutter by:"
    echo "1. Download Flutter from: https://docs.flutter.dev/get-started/install/macos"
    echo "2. Or run: brew install --cask flutter"
    echo ""
fi

# Once Flutter is installed, run these commands:
echo ""
echo "After Flutter is installed, run these commands:"
echo "================================================"
echo ""
echo "cd /Users/skooz/willingtree_app"
echo ""
echo "# Create Flutter project structure"
echo "flutter create . --platforms=ios,android --org com.willingtree --project-name willingtree"
echo ""
echo "# Get dependencies"
echo "flutter pub get"
echo ""
echo "# Run the app"
echo "flutter run"
echo ""
echo "Or to run on specific device:"
echo "flutter run -d chrome  # For web browser"
echo "flutter run -d macos   # For macOS desktop"
echo ""

# Check current directory structure
echo "Current project structure:"
echo "=========================="
ls -la /Users/skooz/willingtree_app/