#!/bin/bash
# Self-Contained APK Build Script (Dynamic Path & AAPT Fix)

# ၁။ သတ်မှတ်ချက်များ (Configuration)
APP_NAME="OcrScannerCSV"
APP_ID="com.example.ocrscanner.csvhybrid"
VERSION_CODE="1"
VERSION_NAME="1.0"

# ဖိုင်နေရာများ
BUILD_DIR="./apk_build"
ASSETS_DIR="www"
MANIFEST_FILE="src/main/AndroidManifest.xml"
KEY_FILE="./key.keystore"
UNSIGNED_APK="$BUILD_DIR/$APP_NAME-unsigned.apk"
SIGNED_APK="$BUILD_DIR/$APP_NAME-signed.apk"
FINAL_APK="$APP_NAME.apk"

echo "--- OCR Scanner APK Build စတင်သည် (Final Fix) ---"

# ဖိုဒါများကို ရှင်းလင်း ဖန်တီးခြင်း
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# www assets များကို assets/www/ အဖြစ် ထားရှိရန်
mkdir -p $BUILD_DIR/assets/www
cp -r $ASSETS_DIR/* $BUILD_DIR/assets/www/

# ============================================
# ၂။ Android SDK Platform Path ကို ရှာဖွေခြင်း (Dynamic Platform Path)
# ============================================
echo "Searching for android.jar..."

# Ubuntu Runner တွင် Android SDK သည် /usr/lib/android-sdk တွင် ရှိသည်ဟု ယူဆပြီး platforms/android-* မှ အမြင့်ဆုံးဗားရှင်းကို ရှာဖွေသည်
# (ဤသည်မှာ android-sdk package ကို apt ဖြင့် ထည့်သွင်းထားသောကြောင့် ဖြစ်သည်။)
ANDROID_PLATFORM_DIR=$(find /usr/lib/android-sdk/platforms -maxdepth 1 -type d -name "android-*" | sort -V | tail -n 1)

if [ -z "$ANDROID_PLATFORM_DIR" ]; then
    echo "ERROR: Android Platform SDK folder မတွေ့ရှိပါ။"
    echo "Check if 'android-sdk' package installed correctly."
    exit 1
fi

ANDROID_JAR="$ANDROID_PLATFORM_DIR/android.jar"
echo "Found Android Platform JAR at: $ANDROID_JAR"

# ============================================
# ၃။ AAPT ဖြင့် APK အား Package လုပ်ခြင်း
# ============================================
echo "Building package using aapt..."

aapt package -f -M $MANIFEST_FILE \
    -A $BUILD_DIR/assets \
    -I $ANDROID_JAR \
    -F $UNSIGNED_APK 

if [ $? -ne 0 ]; then
    echo "ERROR: AAPT packaging failed. Check Android SDK setup."
    exit 1
fi

# ============================================
# ၄။ Keytool ဖြင့် Signing Key ဖန်တီးခြင်း
# ============================================
if [ ! -f "$KEY_FILE" ]; then
    echo "Signing Key အသစ် ဖန်တီးနေသည်..."
    keytool -genkey -v -keystore $KEY_FILE -storepass android -keypass android -alias mykey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=Unknown"
fi

# ============================================
# ၅။ Jarsigner ဖြင့် APK ကို လက်မှတ်ထိုးခြင်း (Sign)
# ============================================
echo "APK အား လက်မှတ်ထိုးနေသည် (Signing)..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEY_FILE -storepass android -keypass android $UNSIGNED_APK mykey
mv $UNSIGNED_APK $SIGNED_APK

# ============================================
# ၆။ Zipalign ဖြင့် APK ကို Optimized လုပ်ခြင်း
# ============================================
echo "APK အား Zipalign ဖြင့် Optimized လုပ်နေသည်..."

# Zipalign သည် build-tools/ တွင် ရှိရမည်
zipalign -f 4 $SIGNED_APK $FINAL_APK

echo "--- APK တည်ဆောက်မှု ပြီးမြောက်ပါပြီ။ $FINAL_APK ကို ရယူနိုင်ပါသည်။ ---"
