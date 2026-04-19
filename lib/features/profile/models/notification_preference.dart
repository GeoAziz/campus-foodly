class NotificationPreference {
  const NotificationPreference({
    this.pushNotifications = true,
    this.orderUpdates = true,
    this.promotions = true,
    this.newRestaurants = true,
    this.restaurantOffers = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final bool pushNotifications;
  final bool orderUpdates;
  final bool promotions;
  final bool newRestaurants;
  final bool restaurantOffers;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      pushNotifications: map['pushNotifications'] as bool? ?? true,
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? true,
      newRestaurants: map['newRestaurants'] as bool? ?? true,
      restaurantOffers: map['restaurantOffers'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] != null
          ? TimeOfDay.fromString(map['quietHoursStart'] as String)
          : null,
      quietHoursEnd: map['quietHoursEnd'] != null
          ? TimeOfDay.fromString(map['quietHoursEnd'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'newRestaurants': newRestaurants,
      'restaurantOffers': restaurantOffers,
      'quietHoursStart': quietHoursStart?.toString(),
      'quietHoursEnd': quietHoursEnd?.toString(),
    };
  }

  NotificationPreference copyWith({
    bool? pushNotifications,
    bool? orderUpdates,
    bool? promotions,
    bool? newRestaurants,
    bool? restaurantOffers,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return NotificationPreference(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      newRestaurants: newRestaurants ?? this.newRestaurants,
      restaurantOffers: restaurantOffers ?? this.restaurantOffers,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

class TimeOfDay {
  const TimeOfDay({required this.hour, required this.minute});

  final int hour;
  final int minute;

  factory TimeOfDay.fromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
