class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
    this.contactEmail,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String status;
  final String? contactEmail;
  final String? logoUrl;

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: (json['id'] as num).toInt(),
    name: json['clubName'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    contactEmail: json['contactEmail'] as String?,
    logoUrl: json['logoUrl'] as String?,
  );
}
