/// Domain model representing a played song entry.
class Song {
  /// Track title.
  final String title;

  /// Artist name.
  final String artist;

  /// Timestamp when the track was played.
  final DateTime timestamp;

  /// Station ID where the song was played.
  final String stationId;

  /// Station display name.
  final String stationName;

  /// Station artwork URL.
  final String stationArtUrl;

  /// Creates an immutable [Song] instance.
  const Song({
    required this.title,
    required this.artist,
    required this.timestamp,
    required this.stationId,
    required this.stationName,
    required this.stationArtUrl,
  });

  /// Serializes the song object to JSON format.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'timestamp': timestamp.toIso8601String(),
      'stationId': stationId,
      'stationName': stationName,
      'stationArtUrl': stationArtUrl,
    };
  }

  /// Deserializes a JSON map into a [Song] instance.
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      stationId: json['stationId'] as String? ?? '',
      stationName: json['stationName'] as String? ?? '',
      stationArtUrl: json['stationArtUrl'] as String? ?? '',
    );
  }
}
