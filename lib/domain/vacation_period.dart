import 'package:freezed_annotation/freezed_annotation.dart';

part 'vacation_period.freezed.dart';
part 'vacation_period.g.dart';

@freezed
class VacationPeriod with _$VacationPeriod {
  const factory VacationPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) = _VacationPeriod;

  factory VacationPeriod.fromJson(Map<String, dynamic> json) =>
      _$VacationPeriodFromJson(json);
}
