# Use official OpenJDK 17 image with Android build tools
FROM openjdk:17-jdk-slim

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/35.0.0

# Install required system packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create Android SDK directory
RUN mkdir -p ${ANDROID_HOME}

# Download and install Android SDK command line tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdtools.zip && \
    unzip -q /tmp/cmdtools.zip -d ${ANDROID_HOME} && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv ${ANDROID_HOME}/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ 2>/dev/null || true && \
    rm /tmp/cmdtools.zip

# Accept Android SDK licenses and install required components
RUN yes | sdkmanager --licenses && \
    sdkmanager --update && \
    sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

# Set working directory
WORKDIR /app

# Copy all files at once (simpler approach)
COPY . .

# Make gradlew executable
RUN chmod +x ./gradlew

# Create local.properties file
RUN echo "sdk.dir=${ANDROID_HOME}" > local.properties

# Create a dummy google-services.json for Firebase
RUN echo '{"project_info":{"project_number":"123456789","project_id":"dummy-project"},"client":[{"client_info":{"mobilesdk_app_id":"1:123456789:android:dummy","android_client_info":{"package_name":"net.devemperor.dictate"}},"oauth_client":[],"api_key":[{"current_key":"dummy-key"}],"services":{"appinvite_service":{"other_platform_oauth_client":[]}}}],"configuration_version":"1"}' > app/google-services.json

# Build the APK
RUN ./gradlew assembleDebug --no-daemon --stacktrace

# Create output directory and rename APK with custom name
RUN mkdir -p /output && \
    VERSION=$(grep 'versionName' app/build.gradle | sed 's/.*"\(.*\)".*/\1/') && \
    cp app/build/outputs/apk/debug/app-debug.apk /output/dictate-v${VERSION}-debug.apk

# Set the default command
CMD ["sh", "-c", "cp /output/*.apk /shared/ && echo 'APK copied successfully' && ls -la /shared/"]

# Expose volume for output
VOLUME ["/shared"]