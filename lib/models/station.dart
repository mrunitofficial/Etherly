import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a radio station.
class Station {
  /// Unique station identifier.
  final String id;

  /// Display name of the station.
  final String name;

  /// Station slogan or tagline.
  final String slogan;

  /// Map of stream quality keys to URL locations.
  final Map<String, String> streams;

  /// Map of resolution size keys to artwork URLs.
  final Map<String, String> art;

  /// Primary category or genre of the station.
  final String category;

  /// Country code associated with the station.
  final String country;

  /// Optional ranking integer.
  final int? rank;

  /// Tags list for searching and filtering.
  final List<String> tags;

  /// Whether the station is currently active.
  final bool active;

  /// Whether the station is marked as user favorite.
  bool isFavorite;

  // Cached numeric resolutions and sorted sizes to optimize getArtUrl lookups
  final List<int> _sortedSizes;
  final Map<int, String> _numericArt;

  /// Creates a [Station] instance.
  Station({
    required this.id,
    required this.name,
    required this.slogan,
    required this.streams,
    required this.art,
    required this.category,
    required this.country,
    this.rank,
    this.tags = const [],
    this.active = true,
    this.isFavorite = false,
  })  : _numericArt = _parseNumericArt(art),
        _sortedSizes = _parseSortedSizes(art);

  static Map<int, String> _parseNumericArt(Map<String, String> art) {
    final numeric = <int, String>{};
    art.forEach((key, value) {
      if (value.isNotEmpty) {
        final parsed = int.tryParse(key);
        if (parsed != null) {
          numeric[parsed] = value;
        }
      }
    });
    return numeric;
  }

  static List<int> _parseSortedSizes(Map<String, String> art) {
    final sizes = <int>[];
    art.forEach((key, value) {
      if (value.isNotEmpty) {
        final parsed = int.tryParse(key);
        if (parsed != null) {
          sizes.add(parsed);
        }
      }
    });
    return sizes..sort();
  }

  /// Deserializes JSON data into a [Station] object.
  factory Station.fromJson(Map<String, dynamic> json, {String? docId}) {
    final Map<String, dynamic> rawStreams =
        json['streams'] as Map<String, dynamic>? ?? {};
    final streams = rawStreams.map(
      (key, value) => MapEntry(key.toLowerCase(), value.toString()),
    );

    // Fallback for old schema if streams map is empty
    if (streams.isEmpty) {
      if (json['streamMP3'] != null) streams['mp3'] = json['streamMP3'];
      if (json['streamAAC'] != null) streams['aac'] = json['streamAAC'];
    }

    final Map<String, String> artMap = {};
    final rawArt = json['art'];
    if (rawArt is Map) {
      rawArt.forEach((k, v) {
        artMap[k.toString()] = v.toString();
      });
    } else if (rawArt is String && rawArt.isNotEmpty) {
      artMap['default'] = rawArt;
    }

    if (json['ArtURL'] is String && json['ArtURL'].isNotEmpty) {
      artMap['default'] = json['ArtURL'];
    }
    if (json['art128'] is String && json['art128'].isNotEmpty) {
      artMap['128'] = json['art128'];
    }
    if (json['art512'] is String && json['art512'].isNotEmpty) {
      artMap['512'] = json['art512'];
    }
    if (json['art1024'] is String && json['art1024'].isNotEmpty) {
      artMap['1024'] = json['art1024'];
    }

    return Station(
      id: docId ?? json['ID'] ?? json['id'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
      slogan: json['slogan'] ?? json['Album'] ?? '',
      streams: streams,
      art: artMap,
      category: json['category'] ?? json['Category'] ?? '',
      country: json['country'] ?? '',
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

  /// Creates a [Station] instance from a Firestore [DocumentSnapshot].
  factory Station.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data was null');
    }
    return Station.fromJson(data, docId: doc.id);
  }

  Station copyWith({
    String? id,
    String? name,
    String? slogan,
    Map<String, String>? streams,
    Map<String, String>? art,
    String? category,
    String? country,
    int? rank,
    List<String>? tags,
    bool? active,
    bool? isFavorite,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      slogan: slogan ?? this.slogan,
      streams: streams ?? this.streams,
      art: art ?? this.art,
      category: category ?? this.category,
      country: country ?? this.country,
      rank: rank ?? this.rank,
      tags: tags ?? this.tags,
      active: active ?? this.active,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Gets the best art URL based on the requested size.
  /// If no size is specified, it defaults to the highest resolution.
  /// Falls back to other sizes or plain art if the desired size is not available.
  String getArtUrl({double? size}) {
    if (art.isEmpty) return '';
    final defaultArt = art['default'] ?? '';

    if (_sortedSizes.isEmpty) {
      return defaultArt;
    }

    if (size == null) {
      final highestNumeric = _numericArt[_sortedSizes.last];
      return (highestNumeric != null && highestNumeric.isNotEmpty)
          ? highestNumeric
          : defaultArt;
    }

    // Find the best fit size: smallest available size that is >= requested size.
    for (final availableSize in _sortedSizes) {
      final url = _numericArt[availableSize];
      if (availableSize >= size && url != null && url.isNotEmpty) {
        return url;
      }
    }

    // If all available sizes are smaller than requested, find the largest available one
    for (int i = _sortedSizes.length - 1; i >= 0; i--) {
      final availableSize = _sortedSizes[i];
      final url = _numericArt[availableSize];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    return defaultArt;
  }
}

/// Helper function to retrieve the best fitting art URL from a size map.
String getArtUrlFromMap(Map<String, String> art, {double? size}) {
  if (art.isEmpty) return '';

  // Extract all numeric keys and map them to their URLs
  final numericSizes = <int, String>{};
  art.forEach((key, value) {
    if (value.isNotEmpty) {
      final parsed = int.tryParse(key);
      if (parsed != null) {
        numericSizes[parsed] = value;
      }
    }
  });

  final defaultArt = art['default'] ?? '';

  if (numericSizes.isEmpty) {
    return defaultArt;
  }

  final sortedSizes = numericSizes.keys.toList()..sort();

  if (size == null) {
    final highestNumeric = numericSizes[sortedSizes.last];
    return (highestNumeric != null && highestNumeric.isNotEmpty)
        ? highestNumeric
        : defaultArt;
  }

  // Find the best fit size: smallest available size that is >= requested size.
  for (final availableSize in sortedSizes) {
    final url = numericSizes[availableSize];
    if (availableSize >= size && url != null && url.isNotEmpty) {
      return url;
      }
    }

  // If all available sizes are smaller than requested, find the largest available one
  for (final availableSize in sortedSizes.reversed) {
    final url = numericSizes[availableSize];
    if (url != null && url.isNotEmpty) {
      return url;
    }
  }

  return defaultArt;
}

