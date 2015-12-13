#!/bin/sh
set -e

# replace all instances /usr/local/include with /usr/local/include/libbson-1.0
sed -i -e "s/\/usr\/local\/include/\/usr\/local\/include\/libbson-1.0/g" ".build/debug/SwiftMongoDB.o/llbuild.yaml"

# run the swift build tool
#/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool -v -f .build/debug/SwiftMongoDB.o/llbuild.yaml
/usr/bin/swift-build-tool -v -f .build/debug/SwiftMongoDB.o/llbuild.yaml
