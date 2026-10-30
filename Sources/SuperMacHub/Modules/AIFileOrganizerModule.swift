import Foundation
import AppKit
import PDFKit
import Vision
import CryptoKit

public struct FileOrganizationProposal: Identifiable, Codable, Hashable {
    public let id: UUID
    public let originalPath: String
    public let originalFilename: String
    public let detectedMimeOrSignature: String
    public let extractedTextSnippet: String
    public var semanticCategory: String
    public var suggestedFilename: String
    public var destinationFolder: String
    public var confidence: Double
    public var reason: String
    public var isDuplicate: Bool
    public var isApproved: Bool
}

public struct FileMoveUndoRecord: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let moves: [(fromPath: String, toPath: String)]

    enum CodingKeys: String, CodingKey {
        case id, timestamp, fromPaths, toPaths
    }

    public init(id: UUID = UUID(), timestamp: Date = Date(), moves: [(fromPath: String, toPath: String)]) {
        self.id = id
        self.timestamp = timestamp
        self.moves = moves
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let froms = try container.decode([String].self, forKey: .fromPaths)
        let tos = try container.decode([String].self, forKey: .toPaths)
        moves = Array(zip(froms, tos))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(moves.map { $0.fromPath }, forKey: .fromPaths)
        try container.encode(moves.map { $0.toPath }, forKey: .toPaths)
    }
}

@MainActor
public final class AIFileOrganizerManager: ObservableObject {
    public static let shared = AIFileOrganizerManager()

    @Published public var targetFolderPath: String = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Downloads").path
    @Published public var proposals: [FileOrganizationProposal] = []
    @Published public var undoHistory: [FileMoveUndoRecord] = []
    @Published public var isScanning: Bool = false
    @Published public var statusMessage: String = "Klasör analizi için hazır (Dry-Run korumalı)."

    private let undoLogURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".supermachub")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("organizer_undo_log.json")
    }()

    private init() {
        loadUndoHistory()
    }

    // MARK: - 3-Layer Scan (Magika Byte Signature + PDF/Vision OCR + Semantic Classifier)
    public func scanFolder(path: String? = nil) {
        let folder = path ?? targetFolderPath
        targetFolderPath = folder
        isScanning = true
        statusMessage = "🔍 Dosyalar Magika byte imzası, PDFKit ve Apple Vision OCR ile taranıyor..."

        Task {
            let url = URL(fileURLWithPath: folder)
            guard let items = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                self.isScanning = false
                self.statusMessage = "Klasör okunamadı. İzinleri kontrol edin."
                return
            }

            var seenHashes: Set<String> = []
            var generatedProposals: [FileOrganizationProposal] = []

            for fileURL in items.prefix(40) {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .creationDateKey]),
                      resourceValues.isRegularFile == true else { continue }

                let signature = Self.detectMagicByteSignature(for: fileURL)
                let hash = Self.computeQuickHash(for: fileURL)
                let isDup = !hash.isEmpty && seenHashes.contains(hash)
                if !hash.isEmpty { seenHashes.insert(hash) }

                let snippet = Self.extractContentSnippet(from: fileURL, signature: signature)
                let createdDate = resourceValues.creationDate ?? Date()
                let classification = Self.classifyFileSemantically(
                    fileURL: fileURL,
                    signature: signature,
                    snippet: snippet,
                    createdDate: createdDate,
                    isDuplicate: isDup
                )

                let destDir = url.appendingPathComponent(classification.category).path
                generatedProposals.append(
                    FileOrganizationProposal(
                        id: UUID(),
                        originalPath: fileURL.path,
                        originalFilename: fileURL.lastPathComponent,
                        detectedMimeOrSignature: signature,
                        extractedTextSnippet: snippet,
                        semanticCategory: classification.category,
                        suggestedFilename: classification.newFilename,
                        destinationFolder: destDir,
                        confidence: classification.confidence,
                        reason: classification.reason,
                        isDuplicate: isDup,
                        isApproved: !isDup
                    )
                )
            }

            self.proposals = generatedProposals
            self.isScanning = false
            self.statusMessage = "✅ \(generatedProposals.count) dosya analiz edildi. Dry-Run listesini inceleyip onaylayabilirsiniz."
        }
    }

    // MARK: - Layer 1: Magika-style Magic Byte Signature Detection
    nonisolated private static func detectMagicByteSignature(for url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url),
              let bytes = try? handle.read(upToCount: 16) else {
            return url.pathExtension.uppercased()
        }
        try? handle.close()

        let hex = bytes.map { String(format: "%02X", $0) }.joined()
        if hex.hasPrefix("25504446") { return "PDF Document (%PDF)" }
        if hex.hasPrefix("89504E47") { return "PNG Image (89PNG)" }
        if hex.hasPrefix("FFD8FF") { return "JPEG Image (FFD8)" }
        if hex.hasPrefix("504B0304") {
            let ext = url.pathExtension.lowercased()
            if ["docx", "xlsx", "pptx"].contains(ext) { return "Office OpenXML (\(ext.uppercased()))" }
            return "ZIP Archive (PK)"
        }
        if hex.hasPrefix("7801") || url.pathExtension.lowercased() == "dmg" { return "macOS Disk Image (DMG)" }
        return "Dosya (\(url.pathExtension.uppercased()))"
    }

    nonisolated private static func computeQuickHash(for url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url),
              let data = try? handle.read(upToCount: 65536) else { return "" }
        try? handle.close()
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Layer 2: Multi-Modal Content Extraction (PDFKit + Vision OCR)
    nonisolated private static func extractContentSnippet(from url: URL, signature: String) -> String {
        let ext = url.pathExtension.lowercased()

        if signature.contains("PDF") || ext == "pdf" {
            if let pdf = PDFDocument(url: url), let page = pdf.page(at: 0), let text = page.string {
                return String(text.replacingOccurrences(of: "\n", with: " ").prefix(240))
            }
        }

        if ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(url: url, options: [:])
            try? handler.perform([request])
            if let results = request.results {
                let recognized = results.prefix(8).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                if !recognized.isEmpty {
                    return String(recognized.prefix(200))
                }
            }
        }

        if ["txt", "md", "json", "csv", "py", "swift", "js", "html"].contains(ext) {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                return String(text.replacingOccurrences(of: "\n", with: " ").prefix(200))
            }
        }

        return ""
    }

    // MARK: - Layer 3: Semantic Categorization & Smart Naming
    nonisolated private static func classifyFileSemantically(
        fileURL: URL,
        signature: String,
        snippet: String,
        createdDate: Date,
        isDuplicate: Bool
    ) -> (category: String, newFilename: String, confidence: Double, reason: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let datePrefix = fmt.string(from: createdDate)

        let origName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        let combined = (origName + " " + snippet).lowercased()

        if isDuplicate {
            return ("99_Kopya_Dosyalar", fileURL.lastPathComponent, 0.99, "SHA-256 içerik özeti birebir aynı olan kopya dosya")
        }

        if combined.contains("fatura") || combined.contains("invoice") || combined.contains("dekont") || combined.contains("makbuz") || combined.contains("kdv") || combined.contains("receipt") {
            let cleanTitle = sanitizeFilename(snippet.isEmpty ? origName : String(snippet.prefix(28)))
            return ("01_Finans_ve_Faturalar", "\(datePrefix)_Fatura_\(cleanTitle).\(ext)", 0.96, "İçerikte finans/fatura/dekont anahtar kelimeleri tespit edildi (RVL-CDIP/CORD sınıfı)")
        }

        if origName.lowercased().contains("screen shot") || origName.lowercased().contains("ekran resmi") || origName.lowercased().contains("screenshot") {
            let ocrHint = snippet.isEmpty ? "EkranGoruntusu" : sanitizeFilename(String(snippet.prefix(25)))
            return ("02_Ekran_Goruntuleri_OCR", "\(datePrefix)_Ekran_\(ocrHint).\(ext)", 0.95, "Vision OCR ile ekran görüntüsü içeriği okundu ve isimlendirildi")
        }

        if ["dmg", "pkg"].contains(ext.lowercased()) {
            return ("03_Kurulum_Paketleri_DMG", fileURL.lastPathComponent, 0.98, "macOS kurulum imajı (Kurulum sonrası silinebilir)")
        }

        if ["pdf", "docx", "doc", "xlsx", "pptx", "pages"].contains(ext.lowercased()) {
            let cleanTitle = sanitizeFilename(origName)
            return ("04_Belgeler_ve_Sunumlar", "\(datePrefix)_\(cleanTitle).\(ext)", 0.91, "Belge/Doküman yapısı tespit edildi")
        }

        if ["zip", "tar", "gz", "rar", "7z"].contains(ext.lowercased()) {
            return ("05_Arsivler", fileURL.lastPathComponent, 0.94, "Sıkıştırılmış arşiv paketi")
        }

        if ["swift", "py", "js", "ts", "json", "yaml", "sh", "html", "css"].contains(ext.lowercased()) {
            return ("06_Kod_ve_Gelistirme", fileURL.lastPathComponent, 0.95, "Kaynak kodu / yapılandırma dosyası")
        }

        if ["png", "jpg", "jpeg", "heic", "webp", "svg", "mp4", "mov", "mp3", "wav"].contains(ext.lowercased()) {
            return ("07_Medya_Gorsel_Ses", "\(datePrefix)_\(sanitizeFilename(origName)).\(ext)", 0.89, "Görsel/Video/Ses medya dosyası")
        }

        return ("08_Diger_Dosyalar", fileURL.lastPathComponent, 0.75, "Genel dosya sınıflandırması")
    }

    nonisolated private static func sanitizeFilename(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let cleaned = raw
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        return cleaned.isEmpty ? "Belge" : String(cleaned.prefix(32))
    }

    // MARK: - Execute Approved Moves & Save Undo Rollback Log
    public func applyApprovedProposals() {
        let approved = proposals.filter { $0.isApproved }
        guard !approved.isEmpty else {
            statusMessage = "Onaylanmış dosya bulunamadı."
            return
        }

        var executedMoves: [(fromPath: String, toPath: String)] = []
        let fm = FileManager.default

        for item in approved {
            let destFolderURL = URL(fileURLWithPath: item.destinationFolder)
            try? fm.createDirectory(at: destFolderURL, withIntermediateDirectories: true)
            let destFileURL = destFolderURL.appendingPathComponent(item.suggestedFilename)

            if fm.fileExists(atPath: item.originalPath) && !fm.fileExists(atPath: destFileURL.path) {
                do {
                    try fm.moveItem(atPath: item.originalPath, toPath: destFileURL.path)
                    executedMoves.append((fromPath: item.originalPath, toPath: destFileURL.path))
                } catch {
                    continue
                }
            }
        }

        if !executedMoves.isEmpty {
            let record = FileMoveUndoRecord(moves: executedMoves)
            undoHistory.insert(record, at: 0)
            saveUndoHistory()
            proposals.removeAll { prop in
                executedMoves.contains { $0.fromPath == prop.originalPath }
            }
            statusMessage = "✅ \(executedMoves.count) dosya başarıyla taşındı ve yeniden adlandırıldı! (Tek tıkla geri alınabilir)"
        }
    }

    public func undoLastBatch() {
        guard let last = undoHistory.first else { return }
        let fm = FileManager.default
        var restored = 0

        for move in last.moves {
            if fm.fileExists(atPath: move.toPath) {
                do {
                    try fm.moveItem(atPath: move.toPath, toPath: move.fromPath)
                    restored += 1
                } catch {
                    continue
                }
            }
        }

        undoHistory.removeFirst()
        saveUndoHistory()
        statusMessage = "↩️ Son işlem geri alındı: \(restored) dosya eski yerine ve adına döndürüldü."
        scanFolder()
    }

    private func saveUndoHistory() {
        if let data = try? JSONEncoder().encode(undoHistory) {
            try? data.write(to: undoLogURL)
        }
    }

    private func loadUndoHistory() {
        if let data = try? Data(contentsOf: undoLogURL),
           let decoded = try? JSONDecoder().decode([FileMoveUndoRecord].self, from: data) {
            undoHistory = decoded
        }
    }
}
