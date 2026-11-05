// ignore_for_file: avoid_redundant_argument_values
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [assignColumns].
///
/// [assignColumns] takes a flat list of [DayScheduleItem]s and returns each one
/// decorated with column-layout information so that overlapping items can be
/// rendered side-by-side on the day timeline.
///
/// Two items overlap when:
///   `a.startTime < b.endTime && b.startTime < a.endTime`
///
/// The algorithm is greedy (sorted by start time) and caps at 3 columns.
void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Builds a [RealDayItem] whose [startTime] and [endTime] are fully
  /// controlled via [start] and [end].
  RealDayItem makeItem(DateTime start, DateTime end) {
    final apt = Appointment(
      id: 'id-${start.millisecondsSinceEpoch}',
      patientId: 'p1',
      providerId: 'prov1',
      date: start,
      concept: 'Consulta',
      totalAmount: 1000,
      endTime: end,
    );
    return RealDayItem(appointment: apt, fallbackDurationMinutes: 45);
  }

  /// Convenience: extract the [DayScheduleItemWithLayout] for [item] from
  /// [results], asserting it is present exactly once.
  DayScheduleItemWithLayout layoutFor(
    List<DayScheduleItemWithLayout> results,
    DayScheduleItem item,
  ) {
    final matches = results.where((r) => r.item == item).toList();
    expect(matches, hasLength(1),
        reason: 'Expected exactly one layout entry for item $item');
    return matches.first;
  }

  // ── Test cases ────────────────────────────────────────────────────────────

  group('assignColumns', () {
    group('empty list', () {
      test('returns empty list when input is empty', () {
        final result = assignColumns([]);
        expect(result, isEmpty);
      });
    });

    group('single item', () {
      test('single item gets col=0 and cols=1', () {
        final item = makeItem(
          DateTime(2025, 3, 10, 8, 0),
          DateTime(2025, 3, 10, 9, 0),
        );

        final result = assignColumns([item]);

        expect(result, hasLength(1));
        final layout = result.first;
        expect(layout.col, 0);
        expect(layout.cols, 1);
      });
    });

    group('two non-overlapping items', () {
      test('item1 ends before item2 starts → both col=0, cols=1', () {
        // item1: 08:00–09:00, item2: 09:00–10:00 (touching, not overlapping)
        final item1 = makeItem(
          DateTime(2025, 3, 10, 8, 0),
          DateTime(2025, 3, 10, 9, 0),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );

        final result = assignColumns([item1, item2]);

        final l1 = layoutFor(result, item1);
        final l2 = layoutFor(result, item2);
        expect(l1.col, 0, reason: 'item1 should be in column 0');
        expect(l1.cols, 1, reason: 'item1 should be alone in its group');
        expect(l2.col, 0, reason: 'item2 should reuse column 0');
        expect(l2.cols, 1, reason: 'item2 should be alone in its group');
      });
    });

    group('two overlapping items', () {
      test('same start time → col=0 and col=1, both cols=2', () {
        final item1 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );

        final result = assignColumns([item1, item2]);

        final l1 = layoutFor(result, item1);
        final l2 = layoutFor(result, item2);
        expect({l1.col, l2.col}, equals({0, 1}),
            reason: 'overlapping items must occupy distinct columns');
        expect(l1.cols, 2);
        expect(l2.cols, 2);
      });

      test('partial overlap → col=0 and col=1, both cols=2', () {
        // item1: 08:30–09:30, item2: 09:00–10:00 — 30-min overlap
        final item1 = makeItem(
          DateTime(2025, 3, 10, 8, 30),
          DateTime(2025, 3, 10, 9, 30),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );

        final result = assignColumns([item1, item2]);

        final l1 = layoutFor(result, item1);
        final l2 = layoutFor(result, item2);
        expect({l1.col, l2.col}, equals({0, 1}));
        expect(l1.cols, 2);
        expect(l2.cols, 2);
      });
    });

    group('three overlapping items', () {
      test('all three overlap → cols=3 for all, cols 0, 1, 2 assigned', () {
        final item1 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item3 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );

        final result = assignColumns([item1, item2, item3]);

        final l1 = layoutFor(result, item1);
        final l2 = layoutFor(result, item2);
        final l3 = layoutFor(result, item3);
        expect({l1.col, l2.col, l3.col}, equals({0, 1, 2}),
            reason: 'three overlapping items must each occupy a distinct column');
        expect(l1.cols, 3);
        expect(l2.cols, 3);
        expect(l3.cols, 3);
      });
    });

    group('four simultaneously overlapping items (cap at 3 columns)', () {
      test('first three get col 0/1/2; fourth is capped at col=2, all cols=3',
          () {
        // All four span the same hour — maximum overlap.
        final item1 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item3 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );
        final item4 = makeItem(
          DateTime(2025, 3, 10, 9, 0),
          DateTime(2025, 3, 10, 10, 0),
        );

        final result = assignColumns([item1, item2, item3, item4]);

        expect(result, hasLength(4));

        final cols = result.map((r) => r.col).toList();
        // Columns 0, 1, 2 should each appear at least once
        expect(cols, contains(0));
        expect(cols, contains(1));
        expect(cols, contains(2));
        // No column index beyond 2 (cap enforced)
        for (final c in cols) {
          expect(c, lessThanOrEqualTo(2),
              reason: 'column index must not exceed 2 (max 3 columns)');
        }
        // Fourth item shares column 2
        final sortedItems =
            result..sort((a, b) => a.col.compareTo(b.col));
        final colTwos =
            sortedItems.where((r) => r.col == 2).toList();
        expect(colTwos.length, 2,
            reason:
                'exactly two items should be stacked in column 2 when 4 overlap');

        // cols count must be 3 for every item
        for (final layout in result) {
          expect(layout.cols, 3,
              reason: 'all items in a 4-way overlap group must report cols=3');
        }
      });
    });

    group('mixed overlapping and non-overlapping groups', () {
      test(
          'item1(0800-0900) and item2(0830-0930) overlap; '
          'item3(1000-1100) is isolated', () {
        final item1 = makeItem(
          DateTime(2025, 3, 10, 8, 0),
          DateTime(2025, 3, 10, 9, 0),
        );
        final item2 = makeItem(
          DateTime(2025, 3, 10, 8, 30),
          DateTime(2025, 3, 10, 9, 30),
        );
        final item3 = makeItem(
          DateTime(2025, 3, 10, 10, 0),
          DateTime(2025, 3, 10, 11, 0),
        );

        final result = assignColumns([item1, item2, item3]);

        final l1 = layoutFor(result, item1);
        final l2 = layoutFor(result, item2);
        final l3 = layoutFor(result, item3);

        // Overlapping group
        expect({l1.col, l2.col}, equals({0, 1}),
            reason: 'item1 and item2 must be in separate columns');
        expect(l1.cols, 2, reason: 'item1 belongs to a 2-item overlap group');
        expect(l2.cols, 2, reason: 'item2 belongs to a 2-item overlap group');

        // Isolated item
        expect(l3.col, 0, reason: 'item3 has no overlap — should reuse col 0');
        expect(l3.cols, 1, reason: 'item3 has no overlap — group size is 1');
      });
    });
  });
}
