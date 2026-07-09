#!/usr/bin/bash

# ponytail: param overrides env default; callers that don't pass one get RelWithDebInfo
BUILD_TYPE="${1:-RelWithDebInfo}"

# Configure cmake build.
echo Configuring cmake build...
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cd ..

