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
