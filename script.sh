#!/bin/bash

# Function to reset dependencies
reset() {
    rm pubspec.lock
    flutter clean
    flutter pub get
}

# Function for the build and localization generation
generate() {
    dart run build_runner build --delete-conflicting-outputs
    dart run import_sorter:main
}

# Function to simulate build in Github Action
test() {
    echo "✨ Check Formatting"
    dart format --line-length 80 --set-exit-if-changed lib test

    echo "🕵️ Analyze"
    flutter analyze lib test

    echo "🧪 Run Tests"
    very_good test -j 4 --coverage --test-randomize-ordering-seed random

    echo "📊 Check Code Coverage"
    genhtml coverage/lcov.info -o coverage/
    open -a "Brave Browser" coverage/index.html
}


# Main menu for selecting an action
echo "Select an action:"
echo "[1] Reset Dependencies"
echo "[2] Code Generation"
echo "[3] Format, Analyze & Test"
read -p "Enter your choice: " choice

case $choice in
    1) reset ;;
    2) generate ;;
    3) test ;;
    *) echo "Invalid selection"; exit 1 ;;
esac