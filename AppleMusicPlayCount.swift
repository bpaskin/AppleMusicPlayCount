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
            // Request recently played songs
            let request = MusicLibraryRequest<Song>()
            let response = try await request.response()

            var artistPlayCounts: [String: Int] = [:]
            for song in response.items {
                if let playCount = song.playCount {
                    artistPlayCounts[song.artistName, default: 0] += playCount
                }
            }

            // Sort artists by total play count in descending order
            let sortedArtists = artistPlayCounts.sorted { $0.value > $1.value }

            // Limit to top 20 artists
            let topArtists = Array(sortedArtists.prefix(20))

            print("Top 20 Artists by Total Listens:")
            for (artist, totalPlays) in topArtists {
                print("- \(artist): \(totalPlays) plays")
            }
        } catch {
            print("Failed to fetch play history: \(error.localizedDescription)")
        }
    }
}
