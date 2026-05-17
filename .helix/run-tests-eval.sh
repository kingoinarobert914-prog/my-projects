#!/bin/bash

# Test runner script that supports running all tests or specific test files
# Usage:
#   ./run-tests-eval.sh              # Run all tests
#   ./run-tests-eval.sh file1,file2  # Run specific test files

set -e

RUN_ALL_TESTS=true
TEST_FILES=""

if [ $# -gt 0 ]; then
    RUN_ALL_TESTS=false
    TEST_FILES="$1"
fi

# Detect and run tests based on project type
run_tests() {
    if [ "$RUN_ALL_TESTS" = true ]; then
        # Run all tests
        if [ -f package.json ]; then
            # Node.js project - detect test runner
            if grep -q '"jest"' package.json; then
                jest
            elif grep -q '"vitest"' package.json; then
                vitest run
            elif grep -q '"mocha"' package.json; then
                mocha
            elif grep -q '"test"' package.json; then
                npm test
            else
                jest 2>/dev/null || vitest run 2>/dev/null || mocha 2>/dev/null || npm test
            fi
        elif [ -f requirements.txt ] || [ -f setup.py ]; then
            # Python project
            pytest
        else
            echo "No test configuration found"
            exit 1
        fi
    else
        # Run specific test files
        IFS=',' read -ra FILES <<< "$TEST_FILES"
        for file in "${FILES[@]}"; do
            file=$(echo "$file" | xargs)  # Trim whitespace
            
            if [[ "$file" == *.js ]] || [[ "$file" == *.jsx ]] || [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
                # JavaScript/TypeScript test file
                if [ -f package.json ] && grep -q '"jest"' package.json; then
                    jest "$file"
                elif [ -f package.json ] && grep -q '"vitest"' package.json; then
                    vitest run "$file"
                elif [ -f package.json ] && grep -q '"mocha"' package.json; then
                    mocha "$file"
                else
                    jest "$file" 2>/dev/null || vitest run "$file" 2>/dev/null || mocha "$file"
                fi
            elif [[ "$file" == *.py ]]; then
                # Python test file
                pytest "$file"
            else
                echo "Unknown test file type: $file"
                exit 1
            fi
        done
    fi
}

run_tests
