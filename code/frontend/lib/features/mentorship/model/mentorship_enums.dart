enum MentorStatus { available, unavailable }

extension MentorStatusX on MentorStatus {
  String get label => switch (this) {
    MentorStatus.available => 'Available',
    MentorStatus.unavailable => 'Unavailable',
  };

  String toApi() => switch (this) {
    MentorStatus.available => 'AVAILABLE',
    MentorStatus.unavailable => 'UNAVAILABLE',
  };

  static MentorStatus fromApi(String? value) => switch (value?.toUpperCase()) {
    'UNAVAILABLE' => MentorStatus.unavailable,
    _ => MentorStatus.available,
  };
}

enum SlotStatus { open, full, closed, cancelled, completed, unknown }

extension SlotStatusX on SlotStatus {
  String get label => switch (this) {
    SlotStatus.open => 'Open',
    SlotStatus.full => 'Full',
    SlotStatus.closed => 'Closed',
    SlotStatus.cancelled => 'Cancelled',
    SlotStatus.completed => 'Completed',
    SlotStatus.unknown => 'Unavailable',
  };

  String toApi() => switch (this) {
    SlotStatus.open => 'OPEN',
    SlotStatus.full => 'FULL',
    SlotStatus.closed => 'CLOSED',
    SlotStatus.cancelled => 'CANCELLED',
    SlotStatus.completed => 'COMPLETED',
    SlotStatus.unknown => 'UNKNOWN',
  };

  static SlotStatus fromApi(String? value) => switch (value?.toUpperCase()) {
    'FULL' => SlotStatus.full,
    'CLOSED' => SlotStatus.closed,
    'CANCELLED' => SlotStatus.cancelled,
    'COMPLETED' => SlotStatus.completed,
    'OPEN' => SlotStatus.open,
    _ => SlotStatus.unknown,
  };
}

enum ScheduleType { oneTime, weekly, biweekly }

extension ScheduleTypeX on ScheduleType {
  String get label => switch (this) {
    ScheduleType.oneTime => 'One-time',
    ScheduleType.weekly => 'Weekly',
    ScheduleType.biweekly => 'Bi-weekly',
  };

  String toApi() => switch (this) {
    ScheduleType.oneTime => 'ONE_TIME',
    ScheduleType.weekly => 'WEEKLY',
    ScheduleType.biweekly => 'BIWEEKLY',
  };

  static ScheduleType fromApi(String? value) => switch (value?.toUpperCase()) {
    'WEEKLY' => ScheduleType.weekly,
    'BIWEEKLY' => ScheduleType.biweekly,
    _ => ScheduleType.oneTime,
  };
}

enum SlotMode { online, inPerson }

extension SlotModeX on SlotMode {
  String get label => switch (this) {
    SlotMode.online => 'Online',
    SlotMode.inPerson => 'In-person',
  };

  String toApi() => switch (this) {
    SlotMode.online => 'ONLINE',
    SlotMode.inPerson => 'IN_PERSON',
  };

  static SlotMode fromApi(String? value) => switch (value?.toUpperCase()) {
    'IN_PERSON' => SlotMode.inPerson,
    _ => SlotMode.online,
  };
}

enum EnrollmentStatus { active, left, cancelled, completed, removed, unknown }

extension EnrollmentStatusX on EnrollmentStatus {
  String get label => switch (this) {
    EnrollmentStatus.active => 'Enrolled',
    EnrollmentStatus.left => 'Left',
    EnrollmentStatus.cancelled => 'Cancelled',
    EnrollmentStatus.completed => 'Completed',
    EnrollmentStatus.removed => 'Removed',
    EnrollmentStatus.unknown => 'Unavailable',
  };

  String toApi() => switch (this) {
    EnrollmentStatus.active => 'ACTIVE',
    EnrollmentStatus.left => 'LEFT',
    EnrollmentStatus.cancelled => 'CANCELLED',
    EnrollmentStatus.completed => 'COMPLETED',
    EnrollmentStatus.removed => 'REMOVED',
    EnrollmentStatus.unknown => 'UNKNOWN',
  };

  static EnrollmentStatus fromApi(String? value) =>
      switch (value?.toUpperCase()) {
        'LEFT' => EnrollmentStatus.left,
        'CANCELLED' => EnrollmentStatus.cancelled,
        'COMPLETED' => EnrollmentStatus.completed,
        'REMOVED' => EnrollmentStatus.removed,
        'ACTIVE' => EnrollmentStatus.active,
        _ => EnrollmentStatus.unknown,
      };
}
