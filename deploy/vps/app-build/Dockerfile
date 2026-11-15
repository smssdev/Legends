# [X104, 2026-11-15] The Android app's builder, on our server (legends-app, deploy/vps/app.sh): a JDK and the tools
# Flutter needs, nothing more. Flutter, the Android SDK, the pub and Gradle caches live in the volume mounted on /cache
# (build.sh installs them on the first build, at the version mobile.yml names), so the image stays small and a second
# build downloads nothing.
FROM eclipse-temurin:21-jdk-noble
RUN apt-get update && apt-get install -y --no-install-recommends git unzip xz-utils curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*
ENV ANDROID_HOME=/cache/android-sdk ANDROID_SDK_ROOT=/cache/android-sdk PUB_CACHE=/cache/pub GRADLE_USER_HOME=/cache/gradle \
    PATH=/cache/flutter/bin:/cache/android-sdk/cmdline-tools/latest/bin:$PATH
COPY build.sh /usr/local/bin/glm-app-build
ENTRYPOINT ["sh", "/usr/local/bin/glm-app-build"]
