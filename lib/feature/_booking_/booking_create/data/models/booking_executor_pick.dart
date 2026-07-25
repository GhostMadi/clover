import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';

/// Исполнитель в черновике услуги — только локально до сохранения.
class BookingExecutorPick {
  const BookingExecutorPick({
    this.staffId,
    this.profileId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
  }) : assert(staffId != null || profileId != null, 'Need staffId or profileId');

  final String? staffId;
  final String? profileId;
  final String displayName;
  final String username;
  final String? avatarUrl;

  String get key => staffId ?? profileId!;

  factory BookingExecutorPick.fromProfile(BookingStaffProfile profile) {
    return BookingExecutorPick(
      profileId: profile.id,
      displayName: profile.title,
      username: profile.username,
      avatarUrl: profile.avatarUrl,
    );
  }

  factory BookingExecutorPick.fromStaff(BookingServiceExecutor staff) {
    return BookingExecutorPick(
      staffId: staff.id,
      profileId: staff.profileId,
      displayName: staff.displayName,
      username: staff.username,
      avatarUrl: staff.avatarUrl,
    );
  }

  BookingServiceExecutor toDisplayExecutor() {
    return BookingServiceExecutor(
      id: key,
      displayName: displayName,
      username: username,
      profileId: profileId,
      avatarUrl: avatarUrl,
    );
  }
}
