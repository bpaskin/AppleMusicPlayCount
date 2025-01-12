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

            // Sort and get top 20 artists
            let sortedArtists = artistPlayCounts.sorted { $0.value > $1.value }
            let topArtists = Array(sortedArtists.prefix(20))

            // Sort and get top 20 songs
            let sortedSongs = songPlayCounts.sorted { $0.value > $1.value }
            let topSongs = Array(sortedSongs.prefix(20))

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
