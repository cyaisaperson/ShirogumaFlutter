class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.patientCode,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.age,
  });

  final String id;
  final String name;
  final String patientCode;
  final int? age;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Patient.fromJson(Map<String, Object?> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      patientCode: json['patientCode'] as String,
      age: json['age'] as int?,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'patientCode': patientCode,
      'age': age,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    String? patientCode,
    int? age,
    bool clearAge = false,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      patientCode: patientCode ?? this.patientCode,
      age: clearAge ? null : age ?? this.age,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
