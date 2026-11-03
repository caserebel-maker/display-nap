#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌙 ================================================"
echo "   กำลังติดตั้ง DisplayNap (macOS Sleep Display Timer)"
echo "   ================================================"

# 1. Build app
"$DIR/build.sh"

# 2. Install .app
APP_SRC="$DIR/build/DisplayNap.app"
DEST_DIR="$HOME/Applications"

if [ -w "/Applications" ]; then
    DEST_DIR="/Applications"
fi

mkdir -p "$DEST_DIR"
echo "==> กำลังคัดลอก $APP_SRC ไปยัง $DEST_DIR/..."
rm -rf "$DEST_DIR/DisplayNap.app"
cp -R "$APP_SRC" "$DEST_DIR/"

# 3. Install CLI tool
CLI_SRC="$DIR/Sources/CLI/displaynap.sh"
CLI_DEST="/usr/local/bin/displaynap"

if [ -w "/usr/local/bin" ]; then
    cp "$CLI_SRC" "$CLI_DEST"
    chmod +x "$CLI_DEST"
    echo "==> ติดตั้ง CLI สำเร็จ: $CLI_DEST (สั่งงานผ่าน Terminal ด้วย 'displaynap 15')"
else
    mkdir -p "$HOME/.local/bin"
    cp "$CLI_SRC" "$HOME/.local/bin/displaynap"
    chmod +x "$HOME/.local/bin/displaynap"
    echo "==> ติดตั้ง CLI สำเร็จ: $HOME/.local/bin/displaynap"
fi

echo ""
echo "🎉 ติดตั้งสำเร็จเรียบร้อย!"
echo "   - แอปจะอยู่ในโฟลเดอร์: $DEST_DIR/DisplayNap.app"
echo "   - สามารถเปิดใช้งานได้ด้วยคำสั่ง: open '$DEST_DIR/DisplayNap.app'"
echo "   - หรือคลิกเปิดจาก Spotlight / Applications"
echo "================================================"

# Launch the app
open "$DEST_DIR/DisplayNap.app"
echo "🚀 เปิด DisplayNap ขึ้นแถบเมนูด้านบนเรียบร้อยแล้ว (สังเกตไอคอน 🌙 บน Menu Bar)"
