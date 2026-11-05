// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MonthlySnapshot {
  /// Document ID — equals [month] (e.g. "2026-03").
  String get id => throw _privateConstructorUsedError;

  /// ISO-format month key: "YYYY-MM".
  String get month => throw _privateConstructorUsedError;

  /// Total revenue collected during this month before reset.
  double get totalRevenue => throw _privateConstructorUsedError;

  /// Total outstanding debt captured at snapshot time (from
  /// `providers/{providerId}/metrics/dashboard.totalToCollect`).
  /// Defaults to 0.0 for backward compatibility with snapshots written
  /// before this field was introduced.
  double get totalDebt => throw _privateConstructorUsedError;

  /// Calendar year (e.g. 2026).
  int get year => throw _privateConstructorUsedError;

  /// Zero-based month index (0 = January … 11 = December).
  int get monthIndex => throw _privateConstructorUsedError;

  /// Server timestamp when the snapshot was written.
  DateTime get savedAt => throw _privateConstructorUsedError;

  /// Create a copy of MonthlySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlySnapshotCopyWith<MonthlySnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlySnapshotCopyWith<$Res> {
  factory $MonthlySnapshotCopyWith(
    MonthlySnapshot value,
    $Res Function(MonthlySnapshot) then,
  ) = _$MonthlySnapshotCopyWithImpl<$Res, MonthlySnapshot>;
  @useResult
  $Res call({
    String id,
    String month,
    double totalRevenue,
    double totalDebt,
    int year,
    int monthIndex,
    DateTime savedAt,
  });
}

/// @nodoc
class _$MonthlySnapshotCopyWithImpl<$Res, $Val extends MonthlySnapshot>
    implements $MonthlySnapshotCopyWith<$Res> {
  _$MonthlySnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? month = null,
    Object? totalRevenue = null,
    Object? totalDebt = null,
    Object? year = null,
    Object? monthIndex = null,
    Object? savedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            month:
                null == month
                    ? _value.month
                    : month // ignore: cast_nullable_to_non_nullable
                        as String,
            totalRevenue:
                null == totalRevenue
                    ? _value.totalRevenue
                    : totalRevenue // ignore: cast_nullable_to_non_nullable
                        as double,
            totalDebt:
                null == totalDebt
                    ? _value.totalDebt
                    : totalDebt // ignore: cast_nullable_to_non_nullable
                        as double,
            year:
                null == year
                    ? _value.year
                    : year // ignore: cast_nullable_to_non_nullable
                        as int,
            monthIndex:
                null == monthIndex
                    ? _value.monthIndex
                    : monthIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            savedAt:
                null == savedAt
                    ? _value.savedAt
                    : savedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonthlySnapshotImplCopyWith<$Res>
    implements $MonthlySnapshotCopyWith<$Res> {
  factory _$$MonthlySnapshotImplCopyWith(
    _$MonthlySnapshotImpl value,
    $Res Function(_$MonthlySnapshotImpl) then,
  ) = __$$MonthlySnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String month,
    double totalRevenue,
    double totalDebt,
    int year,
    int monthIndex,
    DateTime savedAt,
  });
}

/// @nodoc
class __$$MonthlySnapshotImplCopyWithImpl<$Res>
    extends _$MonthlySnapshotCopyWithImpl<$Res, _$MonthlySnapshotImpl>
    implements _$$MonthlySnapshotImplCopyWith<$Res> {
  __$$MonthlySnapshotImplCopyWithImpl(
    _$MonthlySnapshotImpl _value,
    $Res Function(_$MonthlySnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonthlySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? month = null,
    Object? totalRevenue = null,
    Object? totalDebt = null,
    Object? year = null,
    Object? monthIndex = null,
    Object? savedAt = null,
  }) {
    return _then(
      _$MonthlySnapshotImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        month:
            null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                    as String,
        totalRevenue:
            null == totalRevenue
                ? _value.totalRevenue
                : totalRevenue // ignore: cast_nullable_to_non_nullable
                    as double,
        totalDebt:
            null == totalDebt
                ? _value.totalDebt
                : totalDebt // ignore: cast_nullable_to_non_nullable
                    as double,
        year:
            null == year
                ? _value.year
                : year // ignore: cast_nullable_to_non_nullable
                    as int,
        monthIndex:
            null == monthIndex
                ? _value.monthIndex
                : monthIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        savedAt:
            null == savedAt
                ? _value.savedAt
                : savedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$MonthlySnapshotImpl implements _MonthlySnapshot {
  const _$MonthlySnapshotImpl({
    required this.id,
    required this.month,
    required this.totalRevenue,
    this.totalDebt = 0.0,
    required this.year,
    required this.monthIndex,
    required this.savedAt,
  });

  /// Document ID — equals [month] (e.g. "2026-03").
  @override
  final String id;

  /// ISO-format month key: "YYYY-MM".
  @override
  final String month;

  /// Total revenue collected during this month before reset.
  @override
  final double totalRevenue;

  /// Total outstanding debt captured at snapshot time (from
  /// `providers/{providerId}/metrics/dashboard.totalToCollect`).
  /// Defaults to 0.0 for backward compatibility with snapshots written
  /// before this field was introduced.
  @override
  @JsonKey()
  final double totalDebt;

  /// Calendar year (e.g. 2026).
  @override
  final int year;

  /// Zero-based month index (0 = January … 11 = December).
  @override
  final int monthIndex;

  /// Server timestamp when the snapshot was written.
  @override
  final DateTime savedAt;

  @override
  String toString() {
    return 'MonthlySnapshot(id: $id, month: $month, totalRevenue: $totalRevenue, totalDebt: $totalDebt, year: $year, monthIndex: $monthIndex, savedAt: $savedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlySnapshotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalRevenue, totalRevenue) ||
                other.totalRevenue == totalRevenue) &&
            (identical(other.totalDebt, totalDebt) ||
                other.totalDebt == totalDebt) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.monthIndex, monthIndex) ||
                other.monthIndex == monthIndex) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    month,
    totalRevenue,
    totalDebt,
    year,
    monthIndex,
    savedAt,
  );

  /// Create a copy of MonthlySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlySnapshotImplCopyWith<_$MonthlySnapshotImpl> get copyWith =>
      __$$MonthlySnapshotImplCopyWithImpl<_$MonthlySnapshotImpl>(
        this,
        _$identity,
      );
}

abstract class _MonthlySnapshot implements MonthlySnapshot {
  const factory _MonthlySnapshot({
    required final String id,
    required final String month,
    required final double totalRevenue,
    final double totalDebt,
    required final int year,
    required final int monthIndex,
    required final DateTime savedAt,
  }) = _$MonthlySnapshotImpl;

  /// Document ID — equals [month] (e.g. "2026-03").
  @override
  String get id;

  /// ISO-format month key: "YYYY-MM".
  @override
  String get month;

  /// Total revenue collected during this month before reset.
  @override
  double get totalRevenue;

  /// Total outstanding debt captured at snapshot time (from
  /// `providers/{providerId}/metrics/dashboard.totalToCollect`).
  /// Defaults to 0.0 for backward compatibility with snapshots written
  /// before this field was introduced.
  @override
  double get totalDebt;

  /// Calendar year (e.g. 2026).
  @override
  int get year;

  /// Zero-based month index (0 = January … 11 = December).
  @override
  int get monthIndex;

  /// Server timestamp when the snapshot was written.
  @override
  DateTime get savedAt;

  /// Create a copy of MonthlySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlySnapshotImplCopyWith<_$MonthlySnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
