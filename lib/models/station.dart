class Station {
  final String id;
  final String name;
  final String album;
  final String streamMP3;
  final String streamAAC;
  final String artURL;
  final String category;
  final int? rank;
  final List<String> tags;
  bool isFavorite;

  Station({
    required this.id,
    required this.name,
    required this.album,
    required this.streamMP3,
    required this.streamAAC,
    required this.artURL,
    required this.category,
    this.rank,
    this.tags = const [],
    this.isFavorite = false,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['ID'],
      name: json['Name'],
      album: json['Album'],
      streamMP3: json['streamMP3'] ?? '',
      streamAAC: json['streamAAC'] ?? '',
      artURL: json['ArtURL'],
      category: json['Category'],
      rank: json['rank'] is int
          ? json['rank']
          : (json['rank'] is String && json['rank'].isNotEmpty
                ? int.tryParse(json['rank'])
                : null),
      tags:
          (json['Tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Station copyWith({
    String? id,
    String? name,
    String? album,
    String? streamMP3,
    String? streamAAC,
    String? artURL,
    String? category,
    int? rank,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      album: album ?? this.album,
      streamMP3: streamMP3 ?? this.streamMP3,
      streamAAC: streamAAC ?? this.streamAAC,
      artURL: artURL ?? this.artURL,
      category: category ?? this.category,
      rank: rank ?? this.rank,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
