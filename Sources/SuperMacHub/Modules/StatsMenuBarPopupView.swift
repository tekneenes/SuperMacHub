import SwiftUI
import AppKit

public enum StatsPopupTab: String, CaseIterable, Identifiable {
    case portal = "Portal"
    case cpu = "CPU"
    case ram = "RAM"
    case net = "Ağ"
    case diskAndBat = "Disk & Pil"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .portal: return "square.grid.2x2.fill"
        case .cpu: return "cpu.fill"
        case .ram: return "memorychip.fill"
        case .net: return "network"
        case .diskAndBat: return "internaldrive.fill"
        }
    }
}

/// Custom `exelban/stats` Graphical Menu Bar Popover Window (`MenuBarExtraStyle.window`)
public struct StatsMenuBarPopupView: View {
    @ObservedObject var stats = StatsEngine.shared
    @ObservedObject var notch = DynamicIslandNotchManager.shared
    @ObservedObject var utils = SystemUtilitiesManager.shared
    @State private var selectedTab: StatsPopupTab = .portal

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Header Bar + Module Tabs (exelban/stats style)
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 7) {
                        Image(systemName: "chart.bar.xaxis.ascending")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.cyan)
                        Text("SuperMac Stats")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("exelban/stats v2.11")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.18))
                            .foregroundStyle(.cyan)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("Uptime: \(stats.uptimeString)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Segmented Glass Pill Switcher
                HStack(spacing: 4) {
                    ForEach(StatsPopupTab.allCases) { tab in
                        let isSel = (selectedTab == tab)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(isSel ? Color.cyan.opacity(0.28) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(isSel ? Color.cyan.opacity(0.65) : Color.clear, lineWidth: 1)
                            )
                            .foregroundStyle(isSel ? .white : .white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.35))

            Divider().overlay(Color.white.opacity(0.08))

            // 2. Main Tab Content Area
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    switch selectedTab {
                    case .portal:
                        StatsPortalOverviewTab(stats: stats, selectedTab: $selectedTab)
                    case .cpu:
                        StatsCPUPopupDetailTab(stats: stats)
                    case .ram:
                        StatsRAMPopupDetailTab(stats: stats)
                    case .net:
                        StatsNetworkPopupDetailTab(stats: stats)
                    case .diskAndBat:
                        StatsDiskAndBatteryPopupTab(stats: stats, utils: utils)
                    }
                }
                .padding(14)
            }
            .frame(height: 430)

            Divider().overlay(Color.white.opacity(0.08))

            // 3. Bottom Quick Action Bar
            HStack(spacing: 8) {
                Button {
                    if notch.isNotchEnabled { notch.toggleExpanded() } else { notch.showNotchOverlay() }
                } label: {
                    Label(notch.isExpanded ? "Notch Kapat" : "Notch Aç", systemImage: "rectangle.topthird.inset.filled")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    utils.toggleKeepAwake()
                } label: {
                    Label(utils.isKeepAwakeActive ? "Uyanık" : "Caffeinate", systemImage: "cup.and.saucer.fill")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(utils.isKeepAwakeActive ? Color.green.opacity(0.3) : Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    for window in NSApplication.shared.windows where !(window is NSPanel) {
                        window.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    Label("Stüdyo", systemImage: "macwindow")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 10, weight: .bold))
                        .padding(6)
                        .background(Color.red.opacity(0.25))
                        .foregroundStyle(.red)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("SuperMacHub'dan Çık")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.45))
        }
        .frame(width: 390)
        .background(
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09)
                RadialGradient(
                    colors: [Color.cyan.opacity(0.14), Color.purple.opacity(0.08), Color.clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 340
                )
            }
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - TAB 1: Unified exelban/stats Portal Dashboard
private struct StatsPortalOverviewTab: View {
    @ObservedObject var stats: StatsEngine
    @Binding var selectedTab: StatsPopupTab

    var body: some View {
        VStack(spacing: 12) {
            // Top Row: CPU & RAM Multi-Ring Gauges (exelban/stats Portal Cards)
            HStack(spacing: 12) {
                // CPU Portal Card
                Button {
                    selectedTab = .cpu
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            Label("CPU", systemImage: "cpu")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.cyan)
                            Spacer()
                            Text(String(format: "%.0f°C", stats.socTempEstimate))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.orange)
                        }

                        ZStack {
                            Circle().stroke(Color.white.opacity(0.08), lineWidth: 8)
                            // Total usage arc
                            Circle()
                                .trim(from: 0, to: min(1.0, stats.cpuUsagePercent / 100.0))
                                .stroke(
                                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            // System usage inner arc
                            Circle()
                                .trim(from: 0, to: min(1.0, stats.cpuSystemPercent / 100.0))
                                .stroke(Color.pink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 1) {
                                Text("\(Int(stats.cpuUsagePercent))%")
                                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.white)
                                Text("\(stats.cpuCoreCount) Çekirdek")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .frame(width: 78, height: 78)

                        HStack(spacing: 8) {
                            StatsLegendDot(color: .cyan, label: "Usr \(Int(stats.cpuUserPercent))%")
                            StatsLegendDot(color: .pink, label: "Sys \(Int(stats.cpuSystemPercent))%")
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(accent: .cyan, cornerRadius: 16)
                }
                .buttonStyle(.plain)

                // RAM Portal Card
                Button {
                    selectedTab = .ram
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            Label("RAM", systemImage: "memorychip")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.purple)
                            Spacer()
                            Text(String(format: "%.1f GB", stats.memoryUsedGB))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.purple)
                        }

                        ZStack {
                            Circle().stroke(Color.white.opacity(0.08), lineWidth: 8)
                            Circle()
                                .trim(from: 0, to: min(1.0, stats.memoryPressurePercent / 100.0))
                                .stroke(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 1) {
                                Text("\(Int(stats.memoryPressurePercent))%")
                                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.white)
                                Text("\(Int(stats.memoryTotalGB)) GB Toplam")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .frame(width: 78, height: 78)

                        HStack(spacing: 8) {
                            StatsLegendDot(color: .purple, label: "Wired \(String(format: "%.1fG", stats.memoryWiredGB))")
                            StatsLegendDot(color: .orange, label: "Cmp \(String(format: "%.1fG", stats.memoryCompressedGB))")
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(accent: .purple, cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }

            // Network Live Throughput Card
            Button {
                selectedTab = .net
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Ağ Trafiği (\(stats.activeInterfaceName))", systemImage: "network")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.mint)
                        Spacer()
                        Text(stats.localIPAddress)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    HStack(spacing: 14) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.circle.fill").foregroundStyle(.cyan)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("İNDİRME")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(formatSpeed(stats.networkDownloadKBps))
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.circle.fill").foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("YÜKLEME")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(formatSpeed(stats.networkUploadKBps))
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                        Spacer()
                        SparklineAreaChart(values: stats.downloadHistory, color: .cyan)
                            .frame(width: 115, height: 32)
                    }
                }
                .padding(12)
                .liquidGlassCard(accent: .mint, cornerRadius: 14)
            }
            .buttonStyle(.plain)

            // Disk & Battery Bar Card
            Button {
                selectedTab = .diskAndBat
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label(stats.diskVolumeName, systemImage: "internaldrive.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("\(Int(stats.diskFreeGB)) GB Boş")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        ProgressView(value: stats.diskUsagePercent, total: 100)
                            .tint(.orange)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 30).overlay(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label("Pil Sağlığı", systemImage: stats.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.green)
                            Spacer()
                            Text("%\(stats.batteryPercent)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                        ProgressView(value: Double(stats.batteryPercent), total: 100)
                            .tint(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                .liquidGlassCard(accent: .orange, cornerRadius: 14)
            }
            .buttonStyle(.plain)

            // Top 4 Processes Quick List with SIGSTOP Freeze
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("🔥 En Çok Kaynak Tüketen Süreçler")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("CPU / RAM / Dondur")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }

                ForEach(stats.topProcesses.prefix(4)) { proc in
                    HStack(spacing: 8) {
                        Text(proc.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(String(format: "%.1f%%", proc.cpuPercent))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Text("\(String(format: "%.0fM", proc.memoryMB))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.purple)
                            .frame(width: 44, alignment: .trailing)

                        Button {
                            stats.toggleSuspendProcess(pid: proc.pid)
                        } label: {
                            Image(systemName: proc.isSuspended ? "play.fill" : "snowflake")
                                .font(.system(size: 9, weight: .bold))
                                .padding(5)
                                .background(proc.isSuspended ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                                .foregroundStyle(proc.isSuspended ? .green : .cyan)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(proc.isSuspended ? "Süreci Devam Ettir (SIGCONT)" : "Süreci Dondur (SIGSTOP)")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .liquidGlassCard(accent: .cyan, cornerRadius: 14)
        }
    }

    private func formatSpeed(_ kbps: Double) -> String {
        if kbps >= 1024 {
            return String(format: "%.2f MB/s", kbps / 1024.0)
        }
        return String(format: "%.0f KB/s", kbps)
    }
}

// MARK: - TAB 2: exelban/stats CPU Popup Detail View (Per-Core Bars + Load Average + Top CPU)
private struct StatsCPUPopupDetailTab: View {
    @ObservedObject var stats: StatsEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live History Area Chart
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("CPU Kullanım Geçmişi")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text("%\(String(format: "%.1f", stats.cpuUsagePercent))")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.cyan)
                }
                SparklineAreaChart(values: stats.cpuHistory, color: .cyan)
                    .frame(height: 64)
            }
            .padding(12)
            .liquidGlassCard(accent: .cyan, cornerRadius: 14)

            // Per-Core Utilization Bar Grid (exelban/stats Per-Core Histogram)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Çekirdek Bazlı Yük Dağılımı (\(stats.perCoreUsages.count) Çekirdek)")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text("E-Cores & P-Cores")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(stats.perCoreUsages.enumerated()), id: \.offset) { idx, val in
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.08))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: val > 75 ? [.red, .orange] : [.cyan, .blue],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: max(4, geo.size.height * CGFloat(val / 100.0)))
                                }
                            }
                            .frame(height: 52)

                            Text("C\(idx + 1)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .padding(12)
            .liquidGlassCard(accent: .blue, cornerRadius: 14)

            // Telemetry KV Table (User / System / Idle / Load Avg / Temp)
            VStack(spacing: 6) {
                StatsKeyValueRow(label: "Kullanıcı (User):", value: String(format: "%.1f%%", stats.cpuUserPercent), color: .cyan)
                StatsKeyValueRow(label: "Sistem (System):", value: String(format: "%.1f%%", stats.cpuSystemPercent), color: .pink)
                StatsKeyValueRow(label: "Boşta (Idle):", value: String(format: "%.1f%%", stats.cpuIdlePercent), color: .green)
                StatsKeyValueRow(label: "Yük Ortalaması (1/5/15dk):", value: stats.loadAverageString, color: .yellow)
                StatsKeyValueRow(label: "SoC Tahmini Sıcaklık:", value: stats.thermalStateLabel, color: .orange)
            }
            .padding(12)
            .liquidGlassCard(accent: .cyan, cornerRadius: 14)

            // Top CPU Processes
            VStack(alignment: .leading, spacing: 6) {
                Text("En Yüksek CPU Kullanan Süreçler")
                    .font(.system(size: 11, weight: .bold))
                ForEach(stats.topProcesses.prefix(5)) { proc in
                    HStack {
                        Text(proc.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                        Spacer()
                        Text(String(format: "%.1f%%", proc.cpuPercent))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .padding(12)
            .liquidGlassCard(accent: .cyan, cornerRadius: 14)
        }
    }
}

// MARK: - TAB 3: exelban/stats RAM Popup Detail View
private struct StatsRAMPopupDetailTab: View {
    @ObservedObject var stats: StatsEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Bellek Baskısı & Kullanım Geçmişi")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text("\(String(format: "%.2f", stats.memoryUsedGB)) / \(Int(stats.memoryTotalGB)) GB")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.purple)
                }
                SparklineAreaChart(values: stats.memoryHistory, color: .purple)
                    .frame(height: 64)
            }
            .padding(12)
            .liquidGlassCard(accent: .purple, cornerRadius: 14)

            // Breakdown Table
            VStack(spacing: 6) {
                StatsKeyValueRow(label: "Uygulama Belleği (App):", value: String(format: "%.2f GB", stats.memoryAppGB), color: .cyan)
                StatsKeyValueRow(label: "Kilitli Bellek (Wired):", value: String(format: "%.2f GB", stats.memoryWiredGB), color: .purple)
                StatsKeyValueRow(label: "Sıkıştırılmış (Compressed):", value: String(format: "%.2f GB", stats.memoryCompressedGB), color: .orange)
                StatsKeyValueRow(label: "Boş Bellek (Free):", value: String(format: "%.2f GB", stats.memoryFreeGB), color: .green)
                StatsKeyValueRow(label: "Bellek Baskısı (Pressure):", value: "\(Int(stats.memoryPressurePercent))%", color: .pink)
            }
            .padding(12)
            .liquidGlassCard(accent: .purple, cornerRadius: 14)

            // Top Memory Processes
            VStack(alignment: .leading, spacing: 6) {
                Text("En Yüksek Bellek (RAM) Kullanan Uygulamalar")
                    .font(.system(size: 11, weight: .bold))
                ForEach(stats.topMemoryProcesses.prefix(6)) { proc in
                    HStack {
                        Text(proc.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                        Spacer()
                        Text(String(format: "%.0f MB", proc.memoryMB))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(12)
            .liquidGlassCard(accent: .purple, cornerRadius: 14)
        }
    }
}

// MARK: - TAB 4: exelban/stats Network Popup Detail View
private struct StatsNetworkPopupDetailTab: View {
    @ObservedObject var stats: StatsEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Canlı İndirme (↓) Grafiği")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan)
                    Spacer()
                    Text(String(format: "%.1f KB/s", stats.networkDownloadKBps))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.cyan)
                }
                SparklineAreaChart(values: stats.downloadHistory, color: .cyan)
                    .frame(height: 55)

                Divider().overlay(Color.white.opacity(0.08))

                HStack {
                    Text("Canlı Yükleme (↑) Grafiği")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.purple)
                    Spacer()
                    Text(String(format: "%.1f KB/s", stats.networkUploadKBps))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.purple)
                }
                SparklineAreaChart(values: stats.uploadHistory, color: .purple)
                    .frame(height: 55)
            }
            .padding(12)
            .liquidGlassCard(accent: .mint, cornerRadius: 14)

            VStack(spacing: 6) {
                StatsKeyValueRow(label: "Aktif Arayüz:", value: stats.activeInterfaceName, color: .mint)
                StatsKeyValueRow(label: "Yerel IPv4 Adresi:", value: stats.localIPAddress, color: .cyan)
                StatsKeyValueRow(label: "Toplam İndirilen (Oturum):", value: String(format: "%.2f GB", stats.totalDownloadedGB), color: .green)
                StatsKeyValueRow(label: "Toplam Yüklenen (Oturum):", value: String(format: "%.2f GB", stats.totalUploadedGB), color: .purple)
            }
            .padding(12)
            .liquidGlassCard(accent: .cyan, cornerRadius: 14)
        }
    }
}

// MARK: - TAB 5: exelban/stats Disk, Battery & Sensors Popup Detail View
private struct StatsDiskAndBatteryPopupTab: View {
    @ObservedObject var stats: StatsEngine
    @ObservedObject var utils: SystemUtilitiesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Disk Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(stats.diskVolumeName, systemImage: "internaldrive.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("%\(Int(stats.diskUsagePercent)) Dolu")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.orange)
                }
                ProgressView(value: stats.diskUsagePercent, total: 100)
                    .tint(.orange)
                StatsKeyValueRow(label: "Kullanılan Alan:", value: String(format: "%.1f GB", stats.diskUsedGB), color: .orange)
                StatsKeyValueRow(label: "Kullanılabilir Boş Alan:", value: String(format: "%.1f GB", stats.diskFreeGB), color: .green)
                StatsKeyValueRow(label: "Toplam Kapasite:", value: String(format: "%.0f GB", stats.diskTotalGB), color: .white)
            }
            .padding(12)
            .liquidGlassCard(accent: .orange, cornerRadius: 14)

            // Battery & BatFi Guard Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Pil & BatFi Şarj Koruyucu", systemImage: "battery.100.bolt")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                    Spacer()
                    Text("%\(stats.batteryPercent)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.green)
                }
                StatsKeyValueRow(label: "Durum:", value: stats.batteryTimeRemaining, color: .green)
                StatsKeyValueRow(label: "Güç Kaynağı:", value: stats.isPluggedIn ? "AC Güç Adaptörü" : "Dahili Pil", color: .cyan)
                StatsKeyValueRow(label: "SoC Sıcaklık Sensörü:", value: stats.thermalStateLabel, color: .yellow)

                Divider().overlay(Color.white.opacity(0.08))

                HStack {
                    Text("Şarj Tavanı Limiti: %\(Int(utils.chargeLimitPercent))")
                        .font(.system(size: 10, weight: .bold))
                    Slider(value: $utils.chargeLimitPercent, in: 60...100, step: 5)
                }
            }
            .padding(12)
            .liquidGlassCard(accent: .green, cornerRadius: 14)
        }
    }
}

private struct StatsLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}

private struct StatsKeyValueRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
            Spacer()
            Text(value)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
