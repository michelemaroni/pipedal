#!/usr/bin/bash

BUILD_TYPE="${1:-RelWithDebInfo}"

/usr/bin/cmake --build build --config "$BUILD_TYPE" --target all --parallel $(nproc)
