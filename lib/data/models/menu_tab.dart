class MenuTabItem {
  const MenuTabItem({
    required this.id,
    required this.restaurantId,
    required this.title,
    this.position = 0,
  });

  final String id;
  final String restaurantId;
  final String title;
  final int position;

  factory MenuTabItem.fromMap(String id, Map<String, dynamic> data) {
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return MenuTabItem(
      id: id,
      restaurantId: data['restaurantId'] as String? ??
          payload['restaurantId'] as String? ??
          '',
      title: payload['title'] as String? ?? '',
      position: (payload['position'] as num? ?? 0).toInt(),
    );
  }
}