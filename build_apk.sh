#!/bin/bash
# Self-Contained APK Build Script (Termux-APKiZ အစားထိုး)

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
UNALIGNED_APK="$BUILD_DIR/$APP_NAME-unaligned.apk"
FINAL_APK="$APP_NAME.apk"

echo "--- OCR Scanner APK Build စတင်သည် ---"

# ဖိုဒါများကို ရှင်းလင်း ဖန်တီးခြင်း
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $BUILD_DIR/assets/

# www assets များကို build folder သို့ ကူးယူခြင်း
cp -r $ASSETS_DIR/* $BUILD_DIR/assets/

# ယာယီ Base APK ဖန်တီးခြင်း (Webview App ၏ တည်ဆောက်ပုံကို ကိုယ်စားပြုသည်)
zip -r $UNALIGNED_APK $BUILD_DIR/assets/ $MANIFEST_FILE

# Keytool ဖြင့် Signing Key ဖန်တီးခြင်း (ပထမဆုံးအကြိမ်အတွက်)
if [ ! -f "$KEY_FILE" ]; then
    echo "Signing Key အသစ် ဖန်တီးနေသည်..."
    keytool -genkey -v -keystore $KEY_FILE -storepass android -keypass android -alias mykey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=Unknown"
fi

echo "APK အား လက်မှတ်ထိုးနေသည် (Signing)..."
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEY_FILE -storepass android -keypass android $UNALIGNED_APK mykey
mv $UNALIGNED_APK $FINAL_APK

echo "--- APK တည်ဆောက်မှု ပြီးမြောက်ပါပြီ။ $FINAL_APK ကို ရယူနိုင်ပါသည်။ ---"
