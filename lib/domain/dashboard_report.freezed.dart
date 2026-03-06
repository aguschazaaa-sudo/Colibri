// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DashboardReport {
  double get totalToCollect => throw _privateConstructorUsedError;
  double get monthlyRevenue => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Create a copy of DashboardReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardReportCopyWith<DashboardReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardReportCopyWith<$Res> {
  factory $DashboardReportCopyWith(
    DashboardReport value,
    $Res Function(DashboardReport) then,
  ) = _$DashboardReportCopyWithImpl<$Res, DashboardReport>;
  @useResult
  $Res call({
    double totalToCollect,
    double monthlyRevenue,
    DateTime lastUpdated,
  });
}

/// @nodoc
class _$DashboardReportCopyWithImpl<$Res, $Val extends DashboardReport>
    implements $DashboardReportCopyWith<$Res> {
  _$DashboardReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalToCollect = null,
    Object? monthlyRevenue = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _value.copyWith(
            totalToCollect:
                null == totalToCollect
                    ? _value.totalToCollect
                    : totalToCollect // ignore: cast_nullable_to_non_nullable
                        as double,
            monthlyRevenue:
                null == monthlyRevenue
                    ? _value.monthlyRevenue
                    : monthlyRevenue // ignore: cast_nullable_to_non_nullable
                        as double,
            lastUpdated:
                null == lastUpdated
                    ? _value.lastUpdated
                    : lastUpdated // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardReportImplCopyWith<$Res>
    implements $DashboardReportCopyWith<$Res> {
  factory _$$DashboardReportImplCopyWith(
    _$DashboardReportImpl value,
    $Res Function(_$DashboardReportImpl) then,
  ) = __$$DashboardReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double totalToCollect,
    double monthlyRevenue,
    DateTime lastUpdated,
  });
}

/// @nodoc
class __$$DashboardReportImplCopyWithImpl<$Res>
    extends _$DashboardReportCopyWithImpl<$Res, _$DashboardReportImpl>
    implements _$$DashboardReportImplCopyWith<$Res> {
  __$$DashboardReportImplCopyWithImpl(
    _$DashboardReportImpl _value,
    $Res Function(_$DashboardReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalToCollect = null,
    Object? monthlyRevenue = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _$DashboardReportImpl(
        totalToCollect:
            null == totalToCollect
                ? _value.totalToCollect
                : totalToCollect // ignore: cast_nullable_to_non_nullable
                    as double,
        monthlyRevenue:
            null == monthlyRevenue
                ? _value.monthlyRevenue
                : monthlyRevenue // ignore: cast_nullable_to_non_nullable
                    as double,
        lastUpdated:
            null == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$DashboardReportImpl implements _DashboardReport {
  const _$DashboardReportImpl({
    required this.totalToCollect,
    required this.monthlyRevenue,
    required this.lastUpdated,
  });

  @override
  final double totalToCollect;
  @override
  final double monthlyRevenue;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'DashboardReport(totalToCollect: $totalToCollect, monthlyRevenue: $monthlyRevenue, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardReportImpl &&
            (identical(other.totalToCollect, totalToCollect) ||
                other.totalToCollect == totalToCollect) &&
            (identical(other.monthlyRevenue, monthlyRevenue) ||
                other.monthlyRevenue == monthlyRevenue) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, totalToCollect, monthlyRevenue, lastUpdated);

  /// Create a copy of DashboardReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardReportImplCopyWith<_$DashboardReportImpl> get copyWith =>
      __$$DashboardReportImplCopyWithImpl<_$DashboardReportImpl>(
        this,
        _$identity,
      );
}

abstract class _DashboardReport implements DashboardReport {
  const factory _DashboardReport({
    required final double totalToCollect,
    required final double monthlyRevenue,
    required final DateTime lastUpdated,
  }) = _$DashboardReportImpl;

  @override
  double get totalToCollect;
  @override
  double get monthlyRevenue;
  @override
  DateTime get lastUpdated;

  /// Create a copy of DashboardReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardReportImplCopyWith<_$DashboardReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
