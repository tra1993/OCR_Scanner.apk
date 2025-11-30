#!/bin/bash
# Self-Contained APK Build Script (Using AAPT for Robust Packaging)

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

echo "--- OCR Scanner APK Build စတင်သည် (AAPT ဖြင့်) ---"

# ဖိုဒါများကို ရှင်းလင်း ဖန်တီးခြင်း
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# www assets များကို assets/www/ အဖြစ် ထားရှိရန်
mkdir -p $BUILD_DIR/assets/www
cp -r $ASSETS_DIR/* $BUILD_DIR/assets/www/

# ============================================
# ၂။ AAPT ဖြင့် APK အား Package လုပ်ခြင်း (Unsigned/Unaligned APK ကို ဖန်တီးခြင်း)
# *aapt ကို GitHub Actions runner တွင် တွေ့ရမည်ဟု ယူဆသည်*
# ============================================
echo "Building package using aapt..."

# aapt ဖြင့် assets များကို APK ထဲသို့ ထုပ်ပိုးခြင်း
# -f: Overwrite output file
# -M: AndroidManifest.xml path
# -A: Assets folder path
# -I: Android platform libraries path (GitHub Actions environment တွင် အလိုအလျောက် ရယူပါသည်)
# -F: Output APK file
# -S: Resources folder (ဤသည်မှာ Webview အတွက် မလိုအပ်ပါ)
aapt package -f -M $MANIFEST_FILE \
    -A $BUILD_DIR/assets \
    -I /usr/lib/android-sdk/platforms/android-33/android.jar \
    -F $UNSIGNED_APK 

# aapt မအောင်မြင်ပါက error ပြရန်
if [ $? -ne 0 ]; then
    echo "ERROR: AAPT packaging failed. Check Android SDK setup."
    exit 1
fi

# ============================================
# ၃။ Keytool ဖြင့် Signing Key ဖန်တီးခြင်း (ပထမဆုံးအကြိမ်အတွက်)
# ============================================
if [ ! -f "$KEY_FILE" ]; then
    echo "Signing Key အသစ် ဖန်တီးနေသည်..."
    keytool -genkey -v -keystore $KEY_FILE -storepass android -keypass android -alias mykey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=Unknown"
fi

# ============================================
# ၄။ Jarsigner ဖြင့် APK ကို လက်မှတ်ထိုးခြင်း (Sign)
# ============================================
echo "APK အား လက်မှတ်ထိုးနေသည် (Signing)..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEY_FILE -storepass android -keypass android $UNSIGNED_APK mykey
mv $UNSIGNED_APK $SIGNED_APK

# ============================================
# ၅။ Zipalign ဖြင့် APK ကို Optimized လုပ်ခြင်း (Installability အတွက် မရှိမဖြစ်လိုအပ်သည်)
# ============================================
echo "APK အား Zipalign ဖြင့် Optimized လုပ်နေသည်..."
# Zipalign ကို အသုံးပြု၍ APK ကို Memory-aligned ပြုလုပ်ခြင်း
# zipalign ကို GitHub Actions တွင် ထည့်သွင်းထားသည်ဟု ယူဆသည်
zipalign -f 4 $SIGNED_APK $FINAL_APK

echo "--- APK တည်ဆောက်မှု ပြီးမြောက်ပါပြီ။ $FINAL_APK ကို ရယူနိုင်ပါသည်။ ---"
