#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --strong --fatal-warnings \
  lib/mdown.dart \
  test/library_test.dart \
  tool/build.dart \
  tool/reporter.dart

# Run the tests.
echo "Running tests"
pub run test --reporter json -p "vm" | dart tool/reporter.dart

dart --enable-vm-service=8111 --pause-isolates-on-exit --checked test/library_test.dart &
pub run coverage:collect_coverage --port=8111 -o coverage.json --wait-paused --resume-isolates
pub run coverage:format_coverage --report-on=lib --packages=.packages --in=coverage.json --out=lcov.info --lcov

echo "Done"
