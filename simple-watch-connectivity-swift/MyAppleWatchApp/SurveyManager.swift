//
//  SurveyManager.swift
//  MyAppleWatchApp
//

// MARK: - Survey Extension for Loading and Saving
extension Survey {
    
    /// Loads a Survey from a file URL.
    /// - Parameter url: The URL of the file to load the survey from.
    /// - Throws: An error if the file cannot be read or the data cannot be decoded.
    /// - Returns: A `Survey` object.
    static func load(from url: URL) throws -> Survey {
        let jsonData = try Data(contentsOf: url)
        return try JSONDecoder().decode(Survey.self, from: jsonData)
    }
    
    /// Saves a Survey to a file URL.
    /// - Parameters:
    ///   - survey: The `Survey` object to save.
    ///   - url: The URL of the file to save the survey to.
    /// - Throws: An error if the data cannot be encoded or written to the file.
    static func save(_ survey: Survey, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(survey)
        try jsonData.write(to: url, options: [.atomic])
    }
}

// MARK: - Utility Function
/// Converts a title string into a tag-friendly format.
/// - Parameter title: The title string to convert.
/// - Returns: A sanitized string suitable for use as a tag.
func titleToTag(_ title: String) -> String {
    let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        .union(.newlines)
        .union(.illegalCharacters)
        .union(.controlCharacters)
    
    return title
        .components(separatedBy: invalidCharacters)
        .joined()
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: "-")
}

// MARK: - Bundle Extension for Version Numbers
extension Bundle {
    
    /// Retrieves the release version number of the app.
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// Retrieves the build version number of the app.
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
