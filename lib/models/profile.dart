class Profile {
  final String? id;
  final String name;
  final String email;
  final int age;
  final String? photoURL;
  final String? docURL;

  Profile({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    this.photoURL,
    this.docURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'photoURL': photoURL,
      'docURL': docURL,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map, String id) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age']?.toInt() ?? 0,
      photoURL: map['photoURL'],
      docURL: map['docURL'],
    );
  }

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? photoURL,
    String? docURL,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      photoURL: photoURL ?? this.photoURL,
      docURL: docURL ?? this.docURL,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, email: $email, age: $age, photoURL: $photoURL, docURL: $docURL)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.photoURL == photoURL &&
        other.docURL == docURL;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        age.hashCode ^
        photoURL.hashCode ^
        docURL.hashCode;
  }
}
