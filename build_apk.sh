#!/usr/bin/env bash
set -e

# ===============================
# Paths (adjust if needed)
# ===============================
PROJECT_ROOT="$(pwd)"
BUILD_DIR="$PROJECT_ROOT/build/intermediates"
SRC_DIR="$PROJECT_ROOT/src/main/java"
RES_DIR="$PROJECT_ROOT/src/main/res"
ANDROID_JAR="$ANDROID_HOME/platforms/android-36/android.jar"  # adjust to your android.jar
KEYSTORE="$PROJECT_ROOT/debug.keystore"

# Ensure build directories
rm -rf $BUILD_DIR
mkdir -p "$BUILD_DIR/classes"
mkdir -p "$BUILD_DIR/dex"
mkdir -p "$BUILD_DIR/res_flat"

# ===============================
# 1️⃣ Compile resources
# ===============================
echo "[1/8] Compiling resources..."
$ANDROID_HOME/build-tools/aapt2 compile -o "$BUILD_DIR/res_flat" --dir "$RES_DIR"

# ===============================
# 2️⃣ Link resources and generate R.java
# ===============================
echo "[2/8] Linking resources..."
$ANDROID_HOME/build-tools/aapt2 link \
  -o "$BUILD_DIR/base.apk" \
  -I "$ANDROID_JAR" \
  --manifest "$PROJECT_ROOT/src/main/AndroidManifest.xml" \
  --java "$SRC_DIR" \
  --min-sdk-version 21 \
  --target-sdk-version 36 \
  "$BUILD_DIR/res_flat"/*

# ===============================
# 3️⃣ Compile Java sources
# ===============================
echo "[3/8] Compiling Java sources..."
rm -rf "$BUILD_DIR/classes"/*
javac --release 8 \
  -classpath "$ANDROID_JAR" \
  -d "$BUILD_DIR/classes" \
  $(find "$SRC_DIR" -name "*.java")

# ===============================
# 4️⃣ Convert classes to DEX
# ===============================
echo "[4/8] Converting Java classes to DEX..."
dx --dex \
   --output="$BUILD_DIR/classes.dex" \
   "$BUILD_DIR/classes"

# ===============================
# 5️⃣ Add DEX to APK
# ===============================
echo "[5/8] Adding classes.dex to APK..."
cd "$BUILD_DIR"
zip -uj base.apk classes.dex

# ===============================
# 6️⃣ Add native libraries (fixed)
# ===============================
echo "[6/8] Adding native libraries..."

# Copy all .so files into staging folder with correct structure
for ABI_DIR in "$PROJECT_ROOT"/libs/*; do
    ABI=$(basename "$ABI_DIR")
    mkdir -p "$BUILD_DIR/lib/$ABI"
    cp "$ABI_DIR"/*.so "$BUILD_DIR/lib/$ABI/"
done

# Add the staged lib folder to the APK
cd "$BUILD_DIR"
zip -r base.apk lib
cd "$PROJECT_ROOT"

# ===============================
# 7️⃣ Align APK
# ===============================
echo "[7/8] Aligning APK..."
zipalign -f 4 "$BUILD_DIR/base.apk" "$BUILD_DIR/aligned.apk"

# ===============================
# 8️⃣ Sign APK
# ===============================
echo "[8/8] Signing APK..."
if [ ! -f "$KEYSTORE" ]; then
    echo "[!] Keystore not found. Generating debug keystore..."
    keytool -genkeypair \
        -v \
        -keystore "$KEYSTORE" \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass android \
        -keypass android \
        -dname "CN=Android Debug,O=Android,C=US"
fi

apksigner sign \
  --min-sdk-version 21 \
  --ks "$KEYSTORE" \
  --ks-key-alias androiddebugkey \
  --ks-pass pass:android \
  --key-pass pass:android \
  --out "$BUILD_DIR/final.apk" \
  "$BUILD_DIR/aligned.apk"

echo "✅ Build complete! Final APK: $BUILD_DIR/final.apk"
