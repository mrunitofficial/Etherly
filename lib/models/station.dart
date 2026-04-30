import 'package:cloud_firestore/cloud_firestore.dart';

class Station {
  final String id;
  final String name;
  final String slogan;
  final String streamMp3;
  final String streamAac;
  final String art;
  final String category;
  final int? rank;
  final List<String> tags;
  final bool active;
  bool isFavorite;

  Station({
    required this.id,
    required this.name,
    required this.slogan,
    required this.streamMp3,
    required this.streamAac,
    required this.art,
    required this.category,
    this.rank,
    this.tags = const [],
    this.active = true,
    this.isFavorite = false,
  });

  factory Station.fromJson(Map<String, dynamic> json, {String? docId}) {
    final streams = json['streams'] as Map<String, dynamic>? ?? {};
    return Station(
      id: docId ?? json['ID'] ?? json['id'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
      slogan: json['slogan'] ?? json['Album'] ?? '',
      streamMp3: streams['mp3'] ?? json['streamMP3'] ?? '',
      streamAac: streams['aac'] ?? json['streamAAC'] ?? '',
      art: json['art'] ?? json['ArtURL'] ?? '',
      category: json['category'] ?? json['Category'] ?? '',
      rank: json['rank'] is int
          ? json['rank']
          : (json['rank'] is String && json['rank'].isNotEmpty
                ? int.tryParse(json['rank'])
                : null),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['Tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      active: json['active'] ?? true,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  factory Station.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Document data was null");
    }
    return Station.fromJson(data, docId: doc.id);
  }

  Station copyWith({
    String? id,
    String? name,
    String? slogan,
    String? streamMp3,
    String? streamAac,
    String? art,
    String? category,
    int? rank,
    List<String>? tags,
    bool? active,
    bool? isFavorite,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      slogan: slogan ?? this.slogan,
      streamMp3: streamMp3 ?? this.streamMp3,
      streamAac: streamAac ?? this.streamAac,
      art: art ?? this.art,
      category: category ?? this.category,
      rank: rank ?? this.rank,
      tags: tags ?? this.tags,
      active: active ?? this.active,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
