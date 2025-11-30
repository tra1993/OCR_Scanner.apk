#!/bin/bash
# Self-Contained APK Build Script (Debugging $ANDROID_SDK_ROOT)

# ၁။ သတ်မှတ်ချက်များ (Configuration)
APP_NAME="OcrScannerCSV"
APP_ID="com.example.ocrscanner.csvhybrid"
VERSION_CODE="1"
VERSION_NAME="1.0"
ANDROID_API_LEVEL="android-33"

# ဖိုင်နေရာများ
BUILD_DIR="./apk_build"
ASSETS_DIR="www"
MANIFEST_FILE="src/main/AndroidManifest.xml"
KEY_FILE="./key.keystore"
UNSIGNED_APK="$BUILD_DIR/$APP_NAME-unsigned.apk"
SIGNED_APK="$BUILD_DIR/$APP_NAME-signed.apk"
FINAL_APK="$APP_NAME.apk"

echo "--- OCR Scanner APK Build စတင်သည် (Debugging) ---"

# ဖိုဒါများကို ရှင်းလင်း ဖန်တီးခြင်း
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR/assets/www
cp -r $ASSETS_DIR/* $BUILD_DIR/assets/www/

# ============================================
# ၂။ Android SDK Platform Path ကို စစ်ဆေးခြင်း
# ============================================
echo "Finding available android.jar ..."

ANDROID_PLATFORM_JAR=$(find "$ANDROID_SDK_ROOT/platforms" -maxdepth 2 -name "android.jar" | head -n 1)

if [ ! -f "$ANDROID_PLATFORM_JAR" ]; then
    echo "ERROR: android.jar ကို platforms folder ထဲမှာ မတွေ့ရှိနိုင်ဘူး!"
    exit 1
fi

echo "USING ANDROID JAR: $ANDROID_PLATFORM_JAR"

# ============================================
# ၃။ AAPT ဖြင့် APK အား Package လုပ်ခြင်း
# ============================================
echo "Building package using aapt..."

aapt package -f -M $MANIFEST_FILE \
    -A $BUILD_DIR/assets \
    -I $ANDROID_PLATFORM_JAR \
    -F $UNSIGNED_APK 

if [ $? -ne 0 ]; then
    echo "ERROR: AAPT packaging failed."
    exit 1
fi

# ============================================
# ၄။ Keytool / Jarsigner / Zipalign
# ============================================

if [ ! -f "$KEY_FILE" ]; then
    echo "Signing Key အသစ် ဖန်တီးနေသည်..."
    keytool -genkey -v -keystore $KEY_FILE -storepass android -keypass android -alias mykey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=Unknown"
fi

echo "APK အား လက်မှတ်ထိုးနေသည် (Signing)..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEY_FILE -storepass android -keypass android $UNSIGNED_APK mykey
mv $UNSIGNED_APK $SIGNED_APK

echo "APK အား Zipalign ဖြင့် Optimized လုပ်နေသည်..."
zipalign -f 4 $SIGNED_APK $FINAL_APK

echo "--- APK တည်ဆောက်မှု ပြီးမြောက်ပါပြီ။ $FINAL_APK ကို ရယူနိုင်ပါသည်။ ---"
