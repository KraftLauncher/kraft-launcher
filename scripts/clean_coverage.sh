#!/bin/sh

# Remove irrelevant files from coverage report, such as generated code,
# mock files, and constants that should not be tested directly.

dart run remove_from_coverage -f coverage/lcov.info \
  -r '\.g\.dart$' \
  -r '\.mocks\.dart$' \
  -r '\.freezed\.dart$' \
  -r '\.mapper\.dart$' \
  -r 'kraft_launcher/lib/common/generated/.*' \
  -r 'kraft_launcher/lib/common/constants/.*'
