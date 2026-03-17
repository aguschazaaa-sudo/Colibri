// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VacationPeriodImpl _$$VacationPeriodImplFromJson(Map<String, dynamic> json) =>
    _$VacationPeriodImpl(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$$VacationPeriodImplToJson(
  _$VacationPeriodImpl instance,
) => <String, dynamic>{
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
};
