import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/store.dart';

void main() {
  testWidgets('Catálogo, personalización, carrito y pedido simulado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = ShopStore();
    await store.init();
    await tester.pumpWidget(IceCreamApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Ice Cream App'), findsOneWidget);
    await tester.ensureVisible(find.text('Fresa de temporada'));
    await tester.tap(find.text('Fresa de temporada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir · \$ 2.500 COP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Tu bolsa de felicidad'), findsOneWidget);
    await tester.tap(find.text('Continuar con el pedido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 2 caracteres.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.ensureVisible(find.text('Simular pedido'));
    await tester.tap(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    expect(store.orders.single['customer'], 'Ana');
    expect(store.cart, isEmpty);
  });
}
