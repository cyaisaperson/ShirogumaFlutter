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
}
