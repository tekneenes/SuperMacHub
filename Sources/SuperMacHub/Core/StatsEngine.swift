import Foundation
import Darwin
import IOKit.ps

public struct ProcessMetric: Identifiable, Hashable {
    public let id: Int32
    public let pid: Int32
    public let name: String
    public let cpuPercent: Double
    public let memoryMB: Double
    public var isSuspended: Bool
}

@MainActor
public final class StatsEngine: ObservableObject {
    public static let shared = StatsEngine()

    // Live CPU Telemetry (exelban/stats CPU module)
    @Published public var cpuUsagePercent: Double = 14.0
    @Published public var cpuUserPercent: Double = 9.0
    @Published public var cpuSystemPercent: Double = 5.0
    @Published public var cpuIdlePercent: Double = 86.0
    @Published public var cpuCoreCount: Int = ProcessInfo.processInfo.activeProcessorCount
    @Published public var perCoreUsages: [Double] = Array(repeating: 12.0, count: 8)
    @Published public var cpuHistory: [Double] = Array(repeating: 12.0, count: 32)
    @Published public var loadAverageString: String = "1.42, 1.28, 1.15"
    @Published public var uptimeString: String = "0g 4s 12d"

    // Live Memory Telemetry (exelban/stats RAM module)
    @Published public var memoryUsedGB: Double = 8.4
    @Published public var memoryTotalGB: Double = 16.0
    @Published public var memoryFreeGB: Double = 7.6
    @Published public var memoryAppGB: Double = 5.1
    @Published public var memoryWiredGB: Double = 2.1
    @Published public var memoryCompressedGB: Double = 1.2
    @Published public var memoryPressurePercent: Double = 42.0
    @Published public var memoryHistory: [Double] = Array(repeating: 45.0, count: 32)

    // Live Disk Telemetry (exelban/stats Disk module)
    @Published public var diskUsedGB: Double = 180.0
    @Published public var diskTotalGB: Double = 512.0
    @Published public var diskFreeGB: Double = 332.0
    @Published public var diskUsagePercent: Double = 35.0
    @Published public var diskVolumeName: String = "Macintosh HD"

    // Live Network Telemetry (exelban/stats Net module)
    @Published public var networkDownloadKBps: Double = 0.0
    @Published public var networkUploadKBps: Double = 0.0
    @Published public var downloadHistory: [Double] = Array(repeating: 5.0, count: 32)
    @Published public var uploadHistory: [Double] = Array(repeating: 2.0, count: 32)
    @Published public var totalDownloadedGB: Double = 0.0
    @Published public var totalUploadedGB: Double = 0.0
    @Published public var localIPAddress: String = "192.168.1.x"
    @Published public var activeInterfaceName: String = "en0 (Wi-Fi)"

    // Live Battery & Sensors Telemetry (exelban/stats Battery & Sensors module)
    @Published public var batteryPercent: Int = 85
    @Published public var isCharging: Bool = true
    @Published public var isPluggedIn: Bool = true
    @Published public var batteryTimeRemaining: String = "Hesaplanıyor"
    @Published public var thermalStateLabel: String = "Nominal (~38°C)"
    @Published public var socTempEstimate: Double = 41.5

    @Published public var topProcesses: [ProcessMetric] = []
    @Published public var topMemoryProcesses: [ProcessMetric] = []
    @Published public var suspendedPIDs: Set<Int32> = []

    private var timer: Timer?
    private var previousPerCoreTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
    private var previousNetBytes: (rx: UInt64, tx: UInt64, timestamp: TimeInterval)?

    private init() {
        memoryTotalGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        cpuCoreCount = ProcessInfo.processInfo.activeProcessorCount
        perCoreUsages = Array(repeating: 10.0, count: cpuCoreCount)
        sampleAllMetrics()
        startMonitoring()
    }

    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleAllMetrics()
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func sampleAllMetrics() {
        sampleCPUAndPerCore()
        sampleLoadAndUptime()
        sampleMemory()
        sampleDisk()
        sampleNetwork()
        sampleBatteryAndThermal()
        sampleTopProcesses()
    }

    // MARK: - Mach Kernel Per-Core & Total CPU Load (host_processor_info)
    private func sampleCPUAndPerCore() {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else { return }
        defer {
            let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        let coreCount = Int(numCPUsU)
        cpuCoreCount = coreCount
        var currentCores: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        var newCoreUsages: [Double] = []

        var totalUserDiff: UInt64 = 0
        var totalSysDiff: UInt64 = 0
        var totalIdleDiff: UInt64 = 0
        var totalNiceDiff: UInt64 = 0

        for i in 0..<coreCount {
            let offset = Int(CPU_STATE_MAX) * i
            let u = UInt64(max(0, info[offset + Int(CPU_STATE_USER)]))
            let s = UInt64(max(0, info[offset + Int(CPU_STATE_SYSTEM)]))
            let idl = UInt64(max(0, info[offset + Int(CPU_STATE_IDLE)]))
            let n = UInt64(max(0, info[offset + Int(CPU_STATE_NICE)]))
            currentCores.append((u, s, idl, n))

            if previousPerCoreTicks.count == coreCount {
                let prev = previousPerCoreTicks[i]
                let uDiff = u >= prev.user ? u - prev.user : 0
                let sDiff = s >= prev.system ? s - prev.system : 0
                let iDiff = idl >= prev.idle ? idl - prev.idle : 0
                let nDiff = n >= prev.nice ? n - prev.nice : 0

                totalUserDiff += uDiff
                totalSysDiff += sDiff
                totalIdleDiff += iDiff
                totalNiceDiff += nDiff

                let coreTotal = Double(uDiff + sDiff + iDiff + nDiff)
                if coreTotal > 0 {
                    let pct = (Double(uDiff + sDiff + nDiff) / coreTotal) * 100.0
                    newCoreUsages.append(min(100.0, max(1.0, pct)))
                } else {
                    newCoreUsages.append(0.0)
                }
            }
        }

        if !newCoreUsages.isEmpty {
            perCoreUsages = newCoreUsages
            let totalTicks = Double(totalUserDiff + totalSysDiff + totalIdleDiff + totalNiceDiff)
            if totalTicks > 0 {
                cpuUserPercent = (Double(totalUserDiff + totalNiceDiff) / totalTicks) * 100.0
                cpuSystemPercent = (Double(totalSysDiff) / totalTicks) * 100.0
                cpuUsagePercent = min(100.0, max(0.0, cpuUserPercent + cpuSystemPercent))
                cpuIdlePercent = max(0.0, 100.0 - cpuUsagePercent)
                cpuHistory.append(cpuUsagePercent)
                if cpuHistory.count > 32 { cpuHistory.removeFirst() }
            }
        }
        previousPerCoreTicks = currentCores
    }

    private func sampleLoadAndUptime() {
        var loads = [Double](repeating: 0.0, count: 3)
        if getloadavg(&loads, 3) == 3 {
            loadAverageString = String(format: "%.2f  %.2f  %.2f", loads[0], loads[1], loads[2])
        }
        let up = Int(ProcessInfo.processInfo.systemUptime)
        let days = up / 86400
        let hours = (up % 86400) / 3600
        let mins = (up % 3600) / 60
        uptimeString = days > 0 ? "\(days)g \(hours)sa \(mins)dk" : "\(hours)sa \(mins)dk"
    }

    // MARK: - Mach Kernel VM Statistics64
    private func sampleMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }
        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let usedBytes = active + wired + compressed

        let gbDivisor = 1024.0 * 1024.0 * 1024.0
        memoryAppGB = active / gbDivisor
        memoryWiredGB = wired / gbDivisor
        memoryCompressedGB = compressed / gbDivisor
        memoryUsedGB = usedBytes / gbDivisor
        memoryFreeGB = max(0.0, memoryTotalGB - memoryUsedGB)
        memoryPressurePercent = min(100.0, max(0.0, (memoryUsedGB / max(1.0, memoryTotalGB)) * 100.0))

        memoryHistory.append(memoryPressurePercent)
        if memoryHistory.count > 32 { memoryHistory.removeFirst() }
    }

    // MARK: - Disk Space
    private func sampleDisk() {
        let rootURL = URL(fileURLWithPath: "/")
        if let values = try? rootURL.resourceValues(forKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]) {
            diskVolumeName = values.volumeName ?? "Macintosh HD"
            let total = Double(values.volumeTotalCapacity ?? 0)
            let free = Double(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let gb = 1_000_000_000.0
            if total > 0 {
                diskTotalGB = total / gb
                diskFreeGB = free / gb
                diskUsedGB = max(0, diskTotalGB - diskFreeGB)
                diskUsagePercent = (diskUsedGB / diskTotalGB) * 100.0
            }
        }
    }

    // MARK: - Network Throughput & IP Address (getifaddrs)
    private func sampleNetwork() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var totalRX: UInt64 = 0
        var totalTX: UInt64 = 0
        var foundIP: String?

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            if let addr = current.pointee.ifa_addr {
                if (name == "en0" || name == "en1") && addr.pointee.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        foundIP = String(cString: hostname)
                        activeInterfaceName = "\(name) (Wi-Fi / Ethernet)"
                    }
                }
                if (name.hasPrefix("en") || name.hasPrefix("pdp_ip")) && addr.pointee.sa_family == UInt8(AF_LINK),
                   let data = current.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    totalRX += UInt64(data.pointee.ifi_ibytes)
                    totalTX += UInt64(data.pointee.ifi_obytes)
                }
            }
            ptr = current.pointee.ifa_next
        }

        if let ip = foundIP { localIPAddress = ip }
        let gbDiv = 1024.0 * 1024.0 * 1024.0
        totalDownloadedGB = Double(totalRX) / gbDiv
        totalUploadedGB = Double(totalTX) / gbDiv

        let now = Date().timeIntervalSince1970
        if let prev = previousNetBytes {
            let dt = max(0.5, now - prev.timestamp)
            let rxDiff = totalRX >= prev.rx ? totalRX - prev.rx : 0
            let txDiff = totalTX >= prev.tx ? totalTX - prev.tx : 0
            networkDownloadKBps = (Double(rxDiff) / 1024.0) / dt
            networkUploadKBps = (Double(txDiff) / 1024.0) / dt

            let normDown = min(100.0, (networkDownloadKBps / 2048.0) * 100.0)
            let normUp = min(100.0, (networkUploadKBps / 1024.0) * 100.0)
            downloadHistory.append(max(3.0, normDown))
            uploadHistory.append(max(2.0, normUp))
            if downloadHistory.count > 32 { downloadHistory.removeFirst() }
            if uploadHistory.count > 32 { uploadHistory.removeFirst() }
        }
        previousNetBytes = (totalRX, totalTX, now)
    }

    // MARK: - IOKit Battery & Thermal State
    private func sampleBatteryAndThermal() {
        let baseTemp = 36.0 + (cpuUsagePercent * 0.28)
        socTempEstimate = baseTemp
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalStateLabel = String(format: "Serin / Nominal (%.1f°C)", baseTemp)
        case .fair: thermalStateLabel = String(format: "Ilık / Normal (%.1f°C)", baseTemp + 8)
        case .serious: thermalStateLabel = String(format: "Yüksek Isı (%.1f°C)", baseTemp + 18)
        case .critical: thermalStateLabel = String(format: "Kritik Isı (%.1f°C)!", baseTemp + 28)
        @unknown default: thermalStateLabel = "Nominal"
        }

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any] else {
            return
        }

        if let cap = desc[kIOPSCurrentCapacityKey as String] as? Int {
            batteryPercent = cap
        }
        if let charging = desc[kIOPSIsChargingKey as String] as? Bool {
            isCharging = charging
        }
        if let powerState = desc[kIOPSPowerSourceStateKey as String] as? String {
            isPluggedIn = (powerState == kIOPSACPowerValue)
        }
        if let timeToEmpty = desc[kIOPSTimeToEmptyKey as String] as? Int, timeToEmpty > 0 {
            let hrs = timeToEmpty / 60
            let mins = timeToEmpty % 60
            batteryTimeRemaining = "\(hrs)sa \(mins)dk kaldı"
        } else if isCharging {
            batteryTimeRemaining = "Şarj Oluyor (AC Güç)"
        } else {
            batteryTimeRemaining = "Prize Takılı"
        }
    }

    // MARK: - Top Processes (CPU & RAM) & SIGSTOP Freezer
    public func sampleTopProcesses() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-Aceo", "pid,%cpu,rss,comm", "-r"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return }

            let lines = output.components(separatedBy: .newlines).dropFirst()
            var parsed: [ProcessMetric] = []

            for line in lines.prefix(18) {
                let parts = line.trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                guard parts.count >= 4,
                      let pid = Int32(parts[0]),
                      let cpu = Double(parts[1]),
                      let rssKB = Double(parts[2]) else { continue }
                let name = parts.dropFirst(3).joined(separator: " ")
                parsed.append(
                    ProcessMetric(
                        id: pid,
                        pid: pid,
                        name: name,
                        cpuPercent: cpu,
                        memoryMB: rssKB / 1024.0,
                        isSuspended: suspendedPIDs.contains(pid)
                    )
                )
            }
            topProcesses = Array(parsed.prefix(7))
            topMemoryProcesses = Array(parsed.sorted { $0.memoryMB > $1.memoryMB }.prefix(7))
        } catch {}
    }

    public func toggleSuspendProcess(pid: Int32) {
        if suspendedPIDs.contains(pid) {
            kill(pid, SIGCONT)
            suspendedPIDs.remove(pid)
        } else {
            kill(pid, SIGSTOP)
            suspendedPIDs.insert(pid)
        }
        sampleTopProcesses()
    }

    public func terminateProcess(pid: Int32) {
        kill(pid, SIGTERM)
        suspendedPIDs.remove(pid)
        sampleTopProcesses()
    }
}
