class ClubPage<T> {
  const ClubPage(this.items, this.total);
  final List<T> items;
  final int total;

  factory ClubPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => ClubPage(
    (json['items'] as List<dynamic>)
        .map((item) => parse(item as Map<String, dynamic>))
        .toList(),
    (json['totalElements'] as num).toInt(),
  );
}
