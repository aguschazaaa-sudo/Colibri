import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/main.dart';
import 'package:cobrador/router/app_router.dart';

void main() {
  testWidgets('Landing page renders Colibrí brand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [splashShownProvider.overrideWith((ref) => true)],
        child: const ColibrApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the brand name appears in the navbar
    expect(find.text('Colibrí'), findsOneWidget);

    // Verify the hero headline
    expect(find.textContaining('Que tu plata'), findsOneWidget);

    // Verify CTA buttons exist
    expect(find.text('Empezá gratis'), findsAtLeast(1));
  });
}
