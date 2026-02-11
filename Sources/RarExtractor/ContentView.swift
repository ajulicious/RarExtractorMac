import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var statusMessage: String = "Drag and drop a RAR file here to extract."
    @State private var isExtracting: Bool = false
    @State private var progressText: String = ""
    
    var body: some View {
        mainContent
            .padding(40)
            .frame(minWidth: 400, minHeight: 300)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                return self.handleDrop(providers: providers)
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            iconView
            statusView
            if isExtracting {
                extractingView
            }
            selectButton
        }
    }
    
    private var iconView: some View {
        Image(systemName: "archivebox")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
    }
    
    private var statusView: some View {
        Text(statusMessage)
            .font(.headline)
            .multilineTextAlignment(.center)
    }
    
    private var extractingView: some View {
        VStack {
            ProgressView()
            Text(progressText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    private var selectButton: some View {
        Button("Select File...") {
            self.selectFile()
        }
        .disabled(isExtracting)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        let rarType: UTType = UTType(filenameExtension: "rar") ?? .data
        panel.allowedContentTypes = [rarType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
             if let url = panel.url {
                 self.startExtraction(file: url)
             }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        let typeIdentifier: String = UTType.fileURL.identifier
        
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { (item, error) in
            if let error = error {
                print("Error loading item: \(error.localizedDescription)")
                return
            }
            
            var fileURL: URL?
            
            if let url = item as? URL {
                fileURL = url
            } else if let data = item as? Data {
                fileURL = URL(dataRepresentation: data, relativeTo: nil)
            }
            
            if let url = fileURL {
                DispatchQueue.main.async {
                    self.startExtraction(file: url)
                }
            }
        }
        return true
    }
    
    private func startExtraction(file: URL) {
        guard !isExtracting else { return }
        
        let baseName: String = file.deletingPathExtension().lastPathComponent
        let parentDir: URL = file.deletingLastPathComponent()
        let destination: URL = parentDir.appendingPathComponent(baseName)
        
        do {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        } catch {
            self.statusMessage = "Error creating directory: \(error.localizedDescription)"
            return
        }
        
        self.isExtracting = true
        self.statusMessage = "Extracting \(file.lastPathComponent)..."
        self.progressText = "Starting..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try RarLogic.extract(archive: file, to: destination) { output in
                   DispatchQueue.main.async {
                       self.progressText = output
                   }
                }
                
                DispatchQueue.main.async {
                    self.isExtracting = false
                    self.statusMessage = "Extraction completed successfully!"
                    self.progressText = ""
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destination.path)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExtracting = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
