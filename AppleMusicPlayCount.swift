import Foundation
import MusicKit

@main
struct AppleMusicCLI {
    static func main() async {
        print("Requesting authorization to access Apple Music...")
        // Request authorization
        let status = await MusicAuthorization.request()
        switch status {
        case .authorized:
            print("Access granted to Apple Music.")
            await fetchPlayHistory()
        case .denied:
            print("Access denied to Apple Music.")
        case .restricted:
            print("Access restricted to Apple Music.")
        case .notDetermined:
            print("Authorization not determined.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }

    static func fetchPlayHistory() async {
        do {
            // Load existing data from JSON file if it exists
            let fileManager = FileManager.default
            let jsonFilePath = "playHistory.json"
            var savedArtistPlayCounts: [String: Int] = [:]
            var savedSongPlayCounts: [String: Int] = [:]

            if fileManager.fileExists(atPath: jsonFilePath) {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonFilePath)),
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    savedArtistPlayCounts = json["artists"] as? [String: Int] ?? [:]
                    savedSongPlayCounts = json["songs"] as? [String: Int] ?? [:]
                }
            }

            // Request recently played songs
            let request = MusicLibraryRequest<Song>()
            let response = try await request.response()

            // Dictionaries to hold play counts for artists and songs
            var artistPlayCounts: [String: Int] = [:]
            var songPlayCounts: [String: Int] = [:]

            for song in response.items {
                if let playCount = song.playCount {
                    // Track artist play counts
                    artistPlayCounts[song.artistName, default: 0] += playCount

                    // Track song play counts
                    let songIdentifier = "\(song.title) by \(song.artistName)"
                    songPlayCounts[songIdentifier, default: 0] += playCount
                }
            }

            // Update totals as Apple Music - saved data
            for (artist, count) in savedArtistPlayCounts {
                artistPlayCounts[artist, default: 0] -= count
            }

            for (song, count) in savedSongPlayCounts {
                songPlayCounts[song, default: 0] -= count
            }

            // Sort and get top 20 artists
            let sortedArtists = artistPlayCounts.sorted { $0.value > $1.value }
            let topArtists = Array(sortedArtists.prefix(20))

            // Sort and get top 20 songs
            let sortedSongs = songPlayCounts.sorted { $0.value > $1.value }
            let topSongs = Array(sortedSongs.prefix(20))

            // Save updated data to JSON file only if it does not exist
            if !fileManager.fileExists(atPath: jsonFilePath) {
                let updatedData: [String: Any] = [
                    "artists": artistPlayCounts,
                    "songs": songPlayCounts,
                    "dateWritten": ISO8601DateFormatter().string(from: Date())
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: updatedData, options: .prettyPrinted) {
                    try? jsonData.write(to: URL(fileURLWithPath: jsonFilePath))
                }
            }

            print("\nTop 20 Artists by Total Listens:")
            for (artist, totalPlays) in topArtists {
                print("- \(artist): \(totalPlays) plays")
            }

            print("\nTop 20 Songs by Total Listens:")
            for (song, totalPlays) in topSongs {
                print("- \(song): \(totalPlays) plays")
            }
        } catch {
            print("Failed to fetch play history: \(error.localizedDescription)")
        }
    }
}
