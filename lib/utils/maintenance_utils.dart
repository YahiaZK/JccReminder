const double _averageDailyUsageHours = (6.5 * 6) / 7;

DateTime calculateNextMaintenanceDate({
  required DateTime lastMaintenanceDate,
  required int hoursLimit,
}) {
  if (_averageDailyUsageHours <= 0) {
    return lastMaintenanceDate;
  }
  final int daysUntilNext = (hoursLimit / _averageDailyUsageHours).ceil();

  return lastMaintenanceDate.add(Duration(days: daysUntilNext));
}
