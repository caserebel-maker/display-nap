#!/usr/bin/env bash
# DisplayNap CLI - Quick countdown & display sleep for macOS
# Does NOT sleep the machine. Only turns off displays to save power.

PID_FILE="/tmp/displaynap_cli.pid"
TARGET_FILE="/tmp/displaynap_cli_target.txt"

usage() {
    echo "DisplayNap CLI - พักหน้าจออัตโนมัติตามเวลา (เครื่องไม่ sleep)"
    echo ""
    echo "การใช้งาน:"
    echo "  displaynap [นาที]       ตั้งเวลานับถอยหลัง (เช่น displaynap 15)"
    echo "  displaynap now          พักหน้าจอทันที"
    echo "  displaynap status       ดูเวลาที่เหลือ"
    echo "  displaynap cancel       ยกเลิกการนับถอยหลัง"
    echo ""
    echo "ตัวเลือกเวลายอดนิยม:"
    echo "  displaynap 5    (5 นาที)"
    echo "  displaynap 10   (10 นาที)"
    echo "  displaynap 15   (15 นาที)"
    echo "  displaynap 30   (30 นาที)"
    echo "  displaynap 60   (1 ชั่วโมง)"
    exit 0
}

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
fi

ACTION="$1"

if [ "$ACTION" == "now" ]; then
    echo "🌙 กำลังพักหน้าจอทันที (เครื่องยังทำงานปกติ)..."
    /usr/bin/pmset displaysleepnow
    exit 0
fi

if [ "$ACTION" == "cancel" ] || [ "$ACTION" == "stop" ]; then
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null
            rm -f "$PID_FILE" "$TARGET_FILE"
            echo "🛑 ยกเลิกตัวนับเวลาเรียบร้อยแล้ว"
            osascript -e 'display notification "ยกเลิกการพักหน้าจอแล้ว" with title "DisplayNap"' 2>/dev/null || true
            exit 0
        fi
    fi
    echo "ℹ️ ไม่พบตัวนับเวลาที่กำลังทำงานอยู่"
    rm -f "$PID_FILE" "$TARGET_FILE" 2>/dev/null
    exit 0
fi

if [ "$ACTION" == "status" ]; then
    if [ -f "$PID_FILE" ] && [ -f "$TARGET_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        TARGET=$(cat "$TARGET_FILE" 2>/dev/null)
        NOW=$(date +%s)
        REMAINING=$((TARGET - NOW))
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null && [ "$REMAINING" -gt 0 ]; then
            MIN=$((REMAINING / 60))
            SEC=$((REMAINING % 60))
            printf "⏳ กำลังนับถอยหลัง: เหลือเวลาอีก %02d:%02d นาที (PID: %s)\n" "$MIN" "$SEC" "$PID"
            exit 0
        fi
    fi
    echo "ℹ️ ไม่มีตัวนับเวลาทำงานอยู่"
    exit 0
fi

# Check if input is a number
if [[ ! "$ACTION" =~ ^[0-9]+$ ]]; then
    echo "❌ ข้อผิดพลาด: กรุณาระบุจำนวนนาทีเป็นตัวเลข หรือใช้ 'now', 'cancel', 'status'"
    exit 1
fi

MINUTES="$ACTION"
SECONDS_TOTAL=$((MINUTES * 60))
TARGET_TIMESTAMP=$(($(date +%s) + SECONDS_TOTAL))

# Cancel existing timer if any
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
    fi
fi

# Run background countdown
(
    sleep "$SECONDS_TOTAL"
    /usr/bin/pmset displaysleepnow
    rm -f "$PID_FILE" "$TARGET_FILE"
) >/dev/null 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"
echo "$TARGET_TIMESTAMP" > "$TARGET_FILE"

echo "✅ เริ่มนับถอยหลัง $MINUTES นาที..."
echo "💡 หน้าจอจะดับเมื่อครบเวลา โดยที่ระบบยังทำงานตามปกติต่อเนื่อง (เครื่องไม่ Sleep)"
echo "🛑 พิมพ์ 'displaynap cancel' เพื่อยกเลิกได้ตลอดเวลา"

osascript -e "display notification \"เริ่มนับถอยหลัง $MINUTES นาทีแล้ว (เครื่องไม่ sleep)\" with title \"DisplayNap\"" 2>/dev/null || true
