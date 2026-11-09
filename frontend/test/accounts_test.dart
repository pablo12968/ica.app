import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/store.dart';
import 'package:frontend/models.dart';
import 'package:frontend/main.dart';
import 'package:frontend/sounds.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('A late response cannot restore private history after logout', () async {
    final pending = Completer<http.Response>();
    var historyCalls = 0;
    final store = ShopStore(
      serverUrl: 'https://example.test',
      client: MockClient((r) async {
        if (r.url.path == '/api/auth/login') {
          return http.Response(
            '{"token":"a","user":{"id":"a","name":"Ana"}}',
            200,
          );
        }
        if (r.url.path == '/api/orders') {
          if (historyCalls++ == 0) {
            return http.Response('[]', 200);
          }
          return pending.future;
        }
        if (r.url.path == '/api/products') {
          return http.Response('[]', 200);
        }
        return http.Response('', 204);
      }),
    );
    await store.authenticate('ana@example.test', 'password-123');
    final check = expectLater(
      store.refreshOrders(),
      throwsA(isA<OrderFailure>()),
    );
    await store.logout();
    pending.complete(http.Response('[{"id":"private-order"}]', 200));
    await check;
    expect(store.orders, isEmpty);
    expect(store.signedIn, false);
    store.dispose();
  });
  test(
    'Production never falls back to simulated orders without a server',
    () async {
      final store = ShopStore();
      expect(store.demo, false);
      store.add(demoProducts.first, 'Una bola', 'Sin topping');
      await expectLater(
        store.checkout('Ana', ''),
        throwsA(isA<OrderFailure>()),
      );
      expect(store.orders, isEmpty);
    },
  );

  test('Account history comes from API; retries keep reference and logout isolates data', () async {
    var attempts = 0;
    final keys = <String>[];
    final store = ShopStore(
      serverUrl: 'https://example.test',
      client: MockClient((r) async {
        if (r.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'token-a',
              'user': {
                'id': 'a',
                'name': 'Ana',
                'email': 'ana@example.test',
                'role': 'customer',
              },
            }),
            200,
          );
        }
        if (r.url.path == '/api/products') {
          return http.Response(
            '[{"id":1,"name":"Fresa","description":"","category":"Clásicos","price":2500}]',
            200,
          );
        }
        if (r.url.path == '/api/orders') {
          expect(r.headers['Authorization'], 'Bearer token-a');
          if (r.method == 'GET') {
            return http.Response('[{"id":"previous","customer":"Ana"}]', 200);
          }
          keys.add(r.headers['Idempotency-Key']!);
          if (attempts++ == 0) {
            return http.Response('{"message":"Reintenta"}', 503);
          }
          return http.Response('{"id":"new","customer":"Ana"}', 201);
        }
        return http.Response('', 204);
      }),
    );
    await store.authenticate('ana@example.test', 'password-123');
    expect(store.orders.single['id'], 'previous');
    store.add(store.products.first, 'Una bola', 'Sin topping');
    await expectLater(store.checkout('Ana', ''), throwsA(isA<OrderFailure>()));
    expect(store.cart.length, 1);
    await store.checkout('Ana', '');
    expect(keys[0], keys[1]);
    expect(store.cart, isEmpty);
    expect(store.orders.length, 2);
    await store.logout();
    expect(store.signedIn, false);
    expect(store.orders, isEmpty);
    expect(store.favorites, isEmpty);
    store.dispose();
  });

  testWidgets('Registration validates confirmation and switches to login', (
    tester,
  ) async {
    final store = ShopStore(serverUrl: 'https://example.test');
    final sounds = AppSounds(playback: (_) async {});
    addTearDown(sounds.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(IceCreamApp(store: store, sounds: sounds));
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'ana@example.test');
    await tester.enterText(fields.at(2), 'password-test');
    await tester.enterText(fields.at(3), 'different');
    await tester.scrollUntilVisible(
      find.text('Crear cuenta'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(store.signedIn, false);
  });
}
