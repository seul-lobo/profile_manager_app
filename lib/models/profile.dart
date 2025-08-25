class Profile {
  final String? id;
  final String name;
  final String email;
  final int age;
  final String? phoneNumber;
  final String? photoURL;
  final String? docURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    this.phoneNumber,
    this.photoURL,
    this.docURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'docURL': docURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map, String id) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age']?.toInt() ?? 0,
      phoneNumber: map['phoneNumber'],
      photoURL: map['photoURL'],
      docURL: map['docURL'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? phoneNumber,
    String? photoURL,
    String? docURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      docURL: docURL ?? this.docURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  bool get hasProfilePicture => photoURL != null && photoURL!.isNotEmpty;
  
  bool get hasDocument => docURL != null && docURL!.isNotEmpty;

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, email: $email, age: $age, phoneNumber: $phoneNumber, photoURL: $photoURL, docURL: $docURL, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.phoneNumber == phoneNumber &&
        other.photoURL == photoURL &&
        other.docURL == docURL &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        age.hashCode ^
        phoneNumber.hashCode ^
        photoURL.hashCode ^
        docURL.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}