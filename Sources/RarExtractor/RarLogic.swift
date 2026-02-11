import Foundation

struct RarLogic {
    enum ExtractionError: Error, LocalizedError {
        case unrarNotFound
        case extractionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .unrarNotFound:
                return "The 'unrar' utility was not found. Please install it via Homebrew (brew install unrar)."
            case .extractionFailed(let message):
                return "Extraction failed: \(message)"
            }
        }
    }
    
    static func findUnrarPath() -> String? {
        // 1. Check bundled resource first
        if let bundledPath = Bundle.main.path(forResource: "unrar", ofType: nil) {
            return bundledPath
        }
        
        // 2. Common system paths (fallback)
        let paths = [
            "/opt/homebrew/bin/unrar", // Apple Silicon Homebrew
            "/usr/local/bin/unrar",    // Intel Homebrew
            "/usr/bin/unrar"           // System
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // 3. Fallback: Try `which unrar`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["unrar"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty,
               FileManager.default.fileExists(atPath: output) {
                return output
            }
        } catch {
            print("Failed to find unrar via which: \(error)")
        }
        
        return nil
    }
    
    static func extract(archive: URL, to destination: URL, progressHandler: @escaping (String) -> Void) throws {
        guard let unrarPath = findUnrarPath() else {
            throw ExtractionError.unrarNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unrarPath)
        // x: extract with full paths
        // -y: assume yes on all queries
        process.arguments = ["x", "-y", archive.path, destination.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                if !line.isEmpty {
                     DispatchQueue.main.async {
                         progressHandler(line)
                     }
                }
            }
        }
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ExtractionError.extractionFailed("Process exited with code \(process.terminationStatus)")
        }
    }
}
