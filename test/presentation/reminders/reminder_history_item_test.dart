import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/presentation/reminders/widgets/reminder_history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Wraps [widget] in a [MaterialApp] with Spanish locale support,
/// matching the locale used in the reminder widget.
Widget buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es', 'AR')],
    locale: const Locale('es', 'AR'),
    home: Scaffold(body: widget),
  );
}

CommunicationLog makeLog({
  String messageType = 'appointment_reminder',
  String status = 'sent',
  Map<String, String>? variables,
  double totalDebtAtThatTime = 0,
  String patientName = 'Ana García',
}) {
  return CommunicationLog(
    id: 'log-1',
    patientId: 'pat-1',
    providerId: 'prov-1',
    messageId: 'msg-1',
    sentAt: DateTime(2026, 3, 15, 10, 0),
    status: status,
    totalDebtAtThatTime: totalDebtAtThatTime,
    patientName: patientName,
    messageType: messageType,
    variables: variables,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  // Task 7.5.1 — payment_reminder: shows "Aviso de deuda" label and amount from variables
  testWidgets(
    'payment_reminder: shows "Aviso de deuda" label and monto_total from variables',
    (WidgetTester tester) async {
      final log = makeLog(
        messageType: 'payment_reminder',
        variables: {
          'nombre_paciente': 'Ana García',
          'profesional_profesion': 'Lic. Pérez',
          'monto_total': r'$15.000',
          'detalle_origen': 'la suma de 3 turnos pendientes',
          'fechas': '- 15/03/2026: \$5.000\n- 22/03/2026: \$5.000\n- 29/03/2026: \$5.000',
        },
        totalDebtAtThatTime: 15000,
      );

      await tester.pumpWidget(buildTestApp(ReminderHistoryItem(log: log)));
      await tester.pumpAndSettle();

      // Must show the type label
      expect(find.text('Aviso de deuda'), findsOneWidget);

      // Must show monto_total from variables (not raw totalDebtAtThatTime)
      expect(find.textContaining(r'$15.000'), findsWidgets);
    },
  );

  // Task 7.5.2 — appointment_reminder: shows correct label and date/time snippet
  testWidgets(
    'appointment_reminder: shows "Recordatorio de turno" label and date/time',
    (WidgetTester tester) async {
      final log = makeLog(
        messageType: 'appointment_reminder',
        variables: {
          'nombre_paciente': 'Ana García',
          'fecha_turno': '22/03/2026',
          'hora_turno': '10:00',
          'nombre_profesional': 'Dr. López',
          'concepto_turno': 'Consulta',
        },
      );

      await tester.pumpWidget(buildTestApp(ReminderHistoryItem(log: log)));
      await tester.pumpAndSettle();

      expect(find.text('Recordatorio de turno'), findsOneWidget);
      // Should show fecha and hora in snippet
      expect(find.textContaining('22/03/2026'), findsWidgets);
    },
  );

  // Task 7.5.3 — unknown messageType: shows "Recordatorio" without crashing
  testWidgets(
    'unknown messageType: shows "Recordatorio" label without crashing',
    (WidgetTester tester) async {
      final log = makeLog(
        messageType: 'unknown_type',
        variables: null,
      );

      await tester.pumpWidget(buildTestApp(ReminderHistoryItem(log: log)));
      await tester.pumpAndSettle();

      // Should not throw and should show fallback label
      expect(find.text('Recordatorio'), findsOneWidget);
    },
  );

  // Task 7.5.4 — null messageType: shows "Recordatorio" without crashing
  testWidgets(
    'null messageType: shows "Recordatorio" label without crashing',
    (WidgetTester tester) async {
      final log = CommunicationLog(
        id: 'log-null',
        patientId: 'pat-null',
        providerId: 'prov-null',
        messageId: 'msg-null',
        sentAt: DateTime(2026, 3, 15),
        status: 'sent',
        totalDebtAtThatTime: 0,
        patientName: 'Ana García',
        messageType: null, // explicitly null
        variables: null,
      );

      await tester.pumpWidget(buildTestApp(ReminderHistoryItem(log: log)));
      await tester.pumpAndSettle();

      // Should not throw and should show fallback label
      expect(find.text('Recordatorio'), findsOneWidget);
    },
  );
}
