class ClubCreationRequest {
  const ClubCreationRequest({
    required this.id,
    required this.clubName,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.requesterName,
    this.logoUrl,
    this.contactEmail,
    this.rejectionReason,
    this.clubId,
  });
  final int id;
  final String clubName;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? requesterName;
  final String? logoUrl;
  final String? contactEmail;
  final String? rejectionReason;
  final int? clubId;

  factory ClubCreationRequest.fromJson(Map<String, dynamic> json) =>
      ClubCreationRequest(
        id: (json['id'] as num).toInt(),
        clubName: json['clubName'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        requesterName: json['requesterName'] as String?,
        logoUrl: json['logoUrl'] as String?,
        contactEmail: json['contactEmail'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        clubId: (json['clubId'] as num?)?.toInt(),
      );
}
