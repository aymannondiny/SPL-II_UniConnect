class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
    this.contactEmail,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String status;
  final String? contactEmail;

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: (json['id'] as num).toInt(),
    name: json['clubName'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    contactEmail: json['contactEmail'] as String?,
  );
}
