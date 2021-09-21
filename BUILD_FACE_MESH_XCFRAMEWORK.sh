#!/bin/sh

# Create output directories~
mkdir -p ./frameworkbuild/FaceMeshIOSLibFramework/arm64
mkdir -p ./frameworkbuild/FaceMeshIOSLibFramework/x86_64
# XCFramework is how we're going to use it.
mkdir -p ./frameworkbuild/FaceMeshIOSLibFramework/xcframework

# Interesting fact. Bazel `build` command stores cached files in `/private/var/tmp/...` folders
# and when you run build, if it finds cached files, it kind of symlinks the files/folders
# into the `bazel-bin` folder found in the project root. So don't be afraid of re-running builds
# because the files are cached.

# build the arm64 binary framework
bazel build --copt=-fembed-bitcode --apple_bitcode=embedded --config=ios_arm64 mediapipe/examples/ios/facemeshioslib:FaceMeshIOSLibFramework

# The arm64 framework zip will be located at //bazel-bin/mediapipe/examples/ios/facemeshioslib/FaceMeshIOSLibFramework.zip

# Call the framework patcher (First argument = compressed framework.zip, Second argument = header file's name(in this case FaceMeshIOSLib.h))
./mediapipe/examples/ios/facemeshioslib/patch_ios_framework.sh ./bazel-bin/mediapipe/examples/ios/facemeshioslib/FaceMeshIOSLibFramework.zip FaceMeshIOSLib.h

# There will be a resulting patched .framework folder at the same directory, this is our arm64 one, we copy it to our arm64 folder
cp -a ./bazel-bin/mediapipe/examples/ios/facemeshioslib/FaceMeshIOSLibFramework.framework ./frameworkbuild/FaceMeshIOSLibFramework/arm64

# Do the same for x86_64

# build x86_64
bazel build --copt=-fembed-bitcode --apple_bitcode=embedded --config=ios_x86_64 mediapipe/examples/ios/facemeshioslib:FaceMeshIOSLibFramework

# Call the framework patcher
./mediapipe/examples/ios/facemeshioslib/patch_ios_framework.sh ./bazel-bin/mediapipe/examples/ios/facemeshioslib/FaceMeshIOSLibFramework.zip FaceMeshIOSLib.h

# copy the patched framework to our folder
cp -a ./bazel-bin/mediapipe/examples/ios/facemeshioslib/FaceMeshIOSLibFramework.framework ./frameworkbuild/FaceMeshIOSLibFramework/x86_64

# Create xcframework (because the classic lipo method with normal .framework no longer works (shows Building for iOS Simulator, but the linked and embedded framework was built for iOS + iOS Simulator))

xcodebuild -create-xcframework \
  -framework ./frameworkbuild/FaceMeshIOSLibFramework/x86_64/FaceMeshIOSLibFramework.framework \
  -framework ./frameworkbuild/FaceMeshIOSLibFramework/arm64/FaceMeshIOSLibFramework.framework \
  -output ./frameworkbuild/FaceMeshIOSLibFramework/xcframework/FaceMeshIOSLibFramework.xcframework

