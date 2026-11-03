import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var countdownTimer: Timer?
    private var targetDate: Date?
    private var notifyBefore10Sec: Bool = true
    private var didWarn10Sec: Bool = false
    
    // Menu items that update state
    private var statusHeaderItem: NSMenuItem!
    private var cancelMenuItem: NSMenuItem!
    private var warnCheckboxItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusButton(title: "🌙")
        
        buildMenu()
    }
    
    private func setupStatusButton(title: String, subtitle: String? = nil) {
        guard let button = statusItem.button else { return }
        
        if let subtitle = subtitle {
            button.title = "🌙 \(subtitle)"
        } else {
            button.title = "🌙"
        }
    }
    
    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // Status display
        statusHeaderItem = NSMenuItem(title: "สถานะ: ไม่ได้ตั้งเวลา", action: nil, keyEquivalent: "")
        statusHeaderItem.isEnabled = false
        menu.addItem(statusHeaderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Main presets
        let presets: [(String, Int)] = [
            ("⏱️ 5 นาที", 5),
            ("⏱️ 10 นาที", 10),
            ("⏱️ 15 นาที", 15),
            ("⏱️ 30 นาที", 30),
            ("⏱️ 60 นาที (1 ชั่วโมง)", 60)
        ]
        
        for (label, minutes) in presets {
            let item = NSMenuItem(title: label, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            menu.addItem(item)
        }
        
        // More times submenu
        let moreMenu = NSMenu()
        let morePresets: [(String, Int)] = [
            ("⏱️ 1 นาที (สำหรับทดสอบ)", 1),
            ("⏱️ 2 นาที", 2),
            ("⏱️ 20 นาที", 20),
            ("⏱️ 45 นาที", 45),
            ("⏱️ 90 นาที (1.5 ชั่วโมง)", 90),
            ("⏱️ 120 นาที (2 ชั่วโมง)", 120),
            ("⏱️ 180 นาที (3 ชั่วโมง)", 180)
        ]
        for (label, minutes) in morePresets {
            let item = NSMenuItem(title: label, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            moreMenu.addItem(item)
        }
        
        moreMenu.addItem(NSMenuItem.separator())
        let customSubItem = NSMenuItem(title: "✏️ กำหนดนาทีเอง...", action: #selector(customTimeClicked), keyEquivalent: "")
        customSubItem.target = self
        moreMenu.addItem(customSubItem)
        
        let moreItem = NSMenuItem(title: "⏱️ ตัวเลือกเวลาอื่นๆ...", action: nil, keyEquivalent: "")
        moreItem.submenu = moreMenu
        menu.addItem(moreItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Action buttons
        let sleepNowItem = NSMenuItem(title: "⚡ พักหน้าจอทันที (Sleep Display Now)", action: #selector(sleepDisplayNow), keyEquivalent: "s")
        sleepNowItem.keyEquivalentModifierMask = [.command, .option]
        sleepNowItem.target = self
        menu.addItem(sleepNowItem)
        
        cancelMenuItem = NSMenuItem(title: "🛑 ยกเลิกตัวนับเวลา (Cancel Timer)", action: #selector(cancelTimer), keyEquivalent: "c")
        cancelMenuItem.target = self
        cancelMenuItem.isEnabled = false
        menu.addItem(cancelMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings / Info
        warnCheckboxItem = NSMenuItem(title: "🔔 แจ้งเตือนล่วงหน้า 10 วินาที", action: #selector(toggleWarning), keyEquivalent: "")
        warnCheckboxItem.target = self
        warnCheckboxItem.state = notifyBefore10Sec ? .on : .off
        menu.addItem(warnCheckboxItem)
        
        let infoItem = NSMenuItem(title: "💡 เครื่อง & โปรแกรมยังคงทำงานตามปกติ", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        menu.addItem(infoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "🚪 ออกจาก DisplayNap", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func presetClicked(_ sender: NSMenuItem) {
        let minutes = sender.tag
        startCountdown(minutes: minutes)
    }
    
    @objc private func customTimeClicked() {
        let alert = NSAlert()
        alert.messageText = "ตั้งเวลานับถอยหลังพักหน้าจอ"
        alert.informativeText = "กรุณาระบุจำนวนนาทีที่ต้องการพักหน้าจอ (เช่น 25):"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "เริ่มนับถอยหลัง")
        alert.addButton(withTitle: "ยกเลิก")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.stringValue = "20"
        alert.accessoryView = inputField
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let mins = Int(text), mins > 0 {
                startCountdown(minutes: mins)
            } else {
                let errAlert = NSAlert()
                errAlert.messageText = "เวลาไม่ถูกต้อง"
                errAlert.informativeText = "กรุณาระบุตัวเลขจำนวนเต็มบวก (นาที)"
                errAlert.runModal()
            }
        }
    }
    
    private func startCountdown(minutes: Int) {
        countdownTimer?.invalidate()
        let totalSeconds = minutes * 60
        targetDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        didWarn10Sec = false
        
        cancelMenuItem.isEnabled = true
        updateCountdownUI()
        
        sendNotification(title: "เริ่มนับถอยหลัง", message: "จะพักหน้าจอในอีก \(minutes) นาที (เครื่องยังทำงานต่อตามปกติ)")
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        RunLoop.current.add(countdownTimer!, forMode: .common)
    }
    
    private func timerTick() {
        guard let targetDate = targetDate else {
            resetTimerState()
            return
        }
        
        let remaining = Int(targetDate.timeIntervalSinceNow)
        if remaining <= 0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            resetTimerState()
            executeDisplaySleep()
            return
        }
        
        // 10-second warning
        if notifyBefore10Sec && remaining <= 10 && !didWarn10Sec {
            didWarn10Sec = true
            sendNotification(title: "เตือนใกล้ถึงเวลา!", message: "หน้าจอจะพักการทำงานในอีก 10 วินาที")
        }
        
        updateCountdownUI()
    }
    
    private func updateCountdownUI() {
        guard let targetDate = targetDate else { return }
        let remaining = max(0, Int(targetDate.timeIntervalSinceNow))
        let minutes = remaining / 60
        let seconds = remaining % 60
        let timeStr = String(format: "%02d:%02d", minutes, seconds)
        
        setupStatusButton(title: "🌙", subtitle: timeStr)
        statusHeaderItem.title = "⏳ เหลือเวลาอีก: \(timeStr)"
    }
    
    @objc private func cancelTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        targetDate = nil
        resetTimerState()
        sendNotification(title: "ยกเลิกตัวนับเวลา", message: "ยกเลิกการพักหน้าจอเรียบร้อยแล้ว")
    }
    
    private func resetTimerState() {
        setupStatusButton(title: "🌙")
        statusHeaderItem.title = "สถานะ: ไม่ได้ตั้งเวลา"
        cancelMenuItem.isEnabled = false
    }
    
    @objc private func toggleWarning() {
        notifyBefore10Sec.toggle()
        warnCheckboxItem.state = notifyBefore10Sec ? .on : .off
    }
    
    @objc private func sleepDisplayNow() {
        cancelTimer()
        executeDisplaySleep()
    }
    
    private func executeDisplaySleep() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        try? process.run()
    }
    
    private func sendNotification(title: String, message: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedMessage)\" with title \"\(escapedTitle)\" subtitle \"DisplayNap\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
    
    @objc private func quitApp() {
        countdownTimer?.invalidate()
        NSApp.terminate(nil)
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
