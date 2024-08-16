//
//  DataManager.swift
//  MyAppleWatchApp
//

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var files: [URL] = []
    
    func reloadFiles() {
        self.files = []
        let fileManager = FileManager.default
        
        // file:///var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/Documents/ //
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            for file in fileURLs {
                let filename = file.lastPathComponent
                if (filename.hasPrefix("Session")) && (filename.hasSuffix(".zip")) && (!files.contains(file)) {
                    self.files.append(file)
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }

    func deleteFile(at index: Int) {
        let file = files[index]
        do {
            try FileManager.default.removeItem(at: file)
            print("Removed file...")
        } catch {
            print("Error deleting file: \(error)")
        }
        self.reloadFiles()
    }
}
