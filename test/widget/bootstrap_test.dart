import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/app/bootstrap.dart';

void main() {
  testWidgets(
    'mostra a tela de erro quando a inicialização falha e permite tentar '
    'novamente',
    (tester) async {
      var attempts = 0;
      Future<void> initialize() async {
        attempts++;
        if (attempts == 1) throw Exception('falha simulada');
      }

      await tester.pumpWidget(
        Bootstrap(
          initialize: initialize,
          appBuilder: (_) => const MaterialApp(home: Text('app pronto')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível abrir os dados locais'),
        findsOneWidget,
      );
      expect(find.text('app pronto'), findsNothing);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('app pronto'), findsOneWidget);
    },
  );
}
