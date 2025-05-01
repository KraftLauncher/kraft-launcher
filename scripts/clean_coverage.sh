#!/bin/sh

# Remove irrelevant files from coverage report, such as generated code,
# mock files, and constants that should not be tested directly.

dart run remove_from_coverage -f coverage/lcov.info \
  -r '\.g\.dart$' \
  -r '\.mocks\.dart$' \
  -r '\.freezed\.dart$' \
  -r 'lib/common/generated/.*' \
  -r 'lib/common/constants/.*'
