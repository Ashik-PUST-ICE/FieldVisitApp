class Location {
  final int id;
  final String name;
  final String? nameBn;
  final String type;

  const Location({
    required this.id,
    required this.name,
    required this.type,
    this.nameBn,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        nameBn: json['name_bn'] as String?,
        type: (json['type'] ?? '') as String,
      );

  Location copyWith({String? name, String? nameBn}) => Location(
        id: id,
        name: name ?? this.name,
        nameBn: nameBn ?? this.nameBn,
        type: type,
      );

  /// Reads the `data` array out of the gateway's standard envelope.
  ///
  /// The location list is small and always fetched whole, so it is held in
  /// plain state rather than a generated Freezed class.
  static List<Location> listFromResponse(dynamic response) {
    final data = response?.data;

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => Location.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Location.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return const [];
  }

  @override
  bool operator ==(Object other) => other is Location && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
