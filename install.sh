#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌙 ================================================"
echo "   กำลังติดตั้ง DisplayNap (macOS Sleep Display Timer)"
echo "   ================================================"

# Kill old running instance if any
pkill -x "DisplayNap" 2>/dev/null || true

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

# 4. Configure Launch at Login (เปิดอัตโนมัติทุกครั้งที่เข้าสู่ระบบ)
echo "==> กำลังตั้งค่าให้เปิดอัตโนมัติทุกครั้งที่เข้าสู่ระบบ (Launch at Login)..."
osascript -e "tell application \"System Events\" to if not (exists (login item \"DisplayNap\")) then make login item at end with properties {path:\"$DEST_DIR/DisplayNap.app\", hidden:false}" 2>/dev/null || true
echo "==> ตั้งค่า Launch at Login สำเร็จ! (ดูได้ที่ System Settings > General > Login Items)"

echo ""
echo "🎉 ติดตั้งสำเร็จเรียบร้อย!"
echo "   - แอปจะอยู่ในโฟลเดอร์: $DEST_DIR/DisplayNap.app"
echo "   - เปิดใช้งานอัตโนมัติทุกครั้งที่เปิดเครื่อง/ล็อกอิน (สามารถเปิด/ปิดได้ในเมนูของแอป)"
echo "   - สั่งงานด่วนผ่าน Terminal ได้: displaynap 15"
echo "================================================"

# Launch the app
open "$DEST_DIR/DisplayNap.app"
echo "🚀 เปิด DisplayNap ขึ้นแถบเมนูด้านบนเรียบร้อยแล้ว (สังเกตไอคอน 🌙 บน Menu Bar)"
