class Song {
  final String title;
  final String artist;
  final DateTime timestamp;
  final String stationId;
  final String stationName;
  final String stationArtUrl;

  Song({
    required this.title,
    required this.artist,
    required this.timestamp,
    required this.stationId,
    required this.stationName,
    required this.stationArtUrl,
  });

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

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] as String,
      artist: json['artist'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stationId: json['stationId'] as String,
      stationName: json['stationName'] as String,
      stationArtUrl: json['stationArtUrl'] as String,
    );
  }
}
