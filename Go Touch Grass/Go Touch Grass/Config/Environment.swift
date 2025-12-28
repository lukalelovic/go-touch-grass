//
//  Environment.swift
//  Go Touch Grass
//
//  Environment configuration loader
//

import Foundation

enum Environment {
    private static let envPath = ProcessInfo.processInfo.environment["ENV_PATH"] ?? ""

    static var supabaseURL: String {
        if let value = loadEnvVariable(key: "SUPABASE_URL"), !value.isEmpty {
            return value
        }
        fatalError("SUPABASE_URL not found in .env file")
    }

    static var supabaseAnonKey: String {
        if let value = loadEnvVariable(key: "SUPABASE_ANON_KEY"), !value.isEmpty {
            return value
        }
        fatalError("SUPABASE_ANON_KEY not found in .env file")
    }

    private static func loadEnvVariable(key: String) -> String? {
        // First try to load from ProcessInfo (for environment variables)
        if let value = ProcessInfo.processInfo.environment[key] {
            return value
        }

        // Then try to load from .env file
        guard let envFileURL = findEnvFile() else {
            print("Warning: .env file not found")
            return nil
        }

        do {
            let contents = try String(contentsOf: envFileURL, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("#") {
                    continue
                }

                let parts = trimmed.components(separatedBy: "=")
                if parts.count == 2 {
                    let envKey = parts[0].trimmingCharacters(in: .whitespaces)
                    let envValue = parts[1].trimmingCharacters(in: .whitespaces)
                    if envKey == key {
                        return envValue
                    }
                }
            }
        } catch {
            print("Error reading .env file: \(error)")
        }

        return nil
    }

    private static func findEnvFile() -> URL? {
        // Try multiple possible locations for .env file
        let fileManager = FileManager.default

        // 1. Check if ENV_PATH is set
        if !envPath.isEmpty {
            let url = URL(fileURLWithPath: envPath)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        // 2. Check current directory
        let currentDir = fileManager.currentDirectoryPath
        let currentDirEnv = URL(fileURLWithPath: currentDir).appendingPathComponent(".env")
        if fileManager.fileExists(atPath: currentDirEnv.path) {
            return currentDirEnv
        }

        // 3. Check project root (go up from typical app bundle location)
        if let bundlePath = Bundle.main.resourcePath {
            var url = URL(fileURLWithPath: bundlePath)
            // Go up several levels to find project root
            for _ in 0..<5 {
                url.deleteLastPathComponent()
                let envURL = url.appendingPathComponent(".env")
                if fileManager.fileExists(atPath: envURL.path) {
                    return envURL
                }
            }
        }

        return nil
    }
}
