class DocumentModel {
  final String id;
  final String userId;
  final String name;
  final String url;
  final String type;
  final int size;
  final DateTime uploadedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'Document',
      size: map['size']?.toInt() ?? 0,
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(
        map['uploadedAt']?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? url,
    String? type,
    int? size,
    DateTime? uploadedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get fileExtension {
    return name.split('.').last.toUpperCase();
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, userId: $userId, name: $name, url: $url, type: $type, size: $size, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DocumentModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.url == url &&
        other.type == type &&
        other.size == size &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        url.hashCode ^
        type.hashCode ^
        size.hashCode ^
        uploadedAt.hashCode;
  }
}
