/// Canonical domain model representing a Chromecast device.
class CastDevice {
  /// Unique identifier of the cast device.
  final String id;

  /// Human-readable display name of the device.
  final String name;

  /// Optional model name or description of the device.
  final String? model;

  /// Creates an immutable [CastDevice] instance.
  const CastDevice({
    required this.id,
    required this.name,
    this.model,
  });

  /// Factory constructor to create a [CastDevice] from map data.
  factory CastDevice.fromMap(Map<String, dynamic> map) {
    return CastDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      model: map['model'] as String?,
    );
  }

  /// Converts the device object to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model': model,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CastDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
