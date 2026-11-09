import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/store.dart';
import 'package:frontend/models.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailingHistoryStore extends InMemorySharedPreferencesStore {
  FailingHistoryStore() : super.empty();
  bool rejectWrites = true;
  bool throwOnWrite = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (throwOnWrite) throw StateError('Storage unavailable');
    if (rejectWrites) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final throwsError in [false, true]) {
    test(
      'Conserva el carrito si falla guardar y permite reintentar ($throwsError)',
      () async {
        final persistence = FailingHistoryStore()..throwOnWrite = throwsError;
        SharedPreferencesStorePlatform.instance = persistence;
        final store = ShopStore(demo: true);
        await store.init();
        store.add(demoProducts.first, 'Una bola', 'Sin topping');
        await expectLater(
          store.checkout('Ana', ''),
          throwsA(isA<OrderFailure>()),
        );
        expect(store.cart, hasLength(1));
        expect(store.orders, isEmpty);
        persistence.rejectWrites = false;
        persistence.throwOnWrite = false;
        await store.checkout('Ana', '');
        expect(store.cart, isEmpty);
        expect(store.orders, hasLength(1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final restored = ShopStore(demo: true);
        await restored.init();
        expect(restored.orders.single['customer'], 'Ana');
      },
    );
  }
  test(
    'Varios toppings se agrupan sin depender del orden y persisten',
    () async {
      final store = ShopStore(demo: true);
      await store.init();
      expect(
        store.addCustomized(demoProducts.first, 'Una bola', [
          'Fresa fresca',
          'Oreo triturada',
        ], 2),
        isTrue,
      );
      expect(
        store.addCustomized(demoProducts.first, 'Una bola', [
          'Oreo triturada',
          'Fresa fresca',
        ], 1),
        isTrue,
      );
      expect(store.cart, hasLength(1));
      expect(store.total, 1200000);
      expect(
        store.addCustomized(demoProducts.first, 'Una bola', [
          'Oreo triturada',
          'Fresa fresca',
        ], 20),
        isFalse,
      );
      expect(store.total, 1200000);
      await store.loadProducts();
      expect(store.total, 1200000);
      await store.checkout('Ana', '');
      final restored = ShopStore(demo: true);
      await restored.init();
      expect(restored.orders.single['items'][0]['toppings'], [
        'Fresa fresca',
        'Oreo triturada',
      ]);
    },
  );
  test('Agrupa configuraciones iguales y calcula extras por unidad', () {
    final store = ShopStore(demo: true);
    store.add(demoProducts.first, 'Dos bolas', 'Chocolate');
    store.add(demoProducts.first, 'Dos bolas', 'Chocolate');
    expect(store.cart.length, 1);
    expect(store.total, 800000);
    store.changeQuantity(store.cart.first, -1);
    expect(store.total, 400000);
    store.changeQuantity(store.cart.first, -1);
    expect(store.cart, isEmpty);
  });
  test('El pedido simulado persiste y vacía el carrito', () async {
    final store = ShopStore(demo: true);
    await store.init();
    store.add(demoProducts.first, 'Una bola', 'Sin topping');
    await store.checkout('Ana', 'Gracias');
    expect(store.orders.single['status'], 'Simulado');
    expect(store.orders.single['total'], 250000);
    expect(
      store.orders.single['id'],
      matches(RegExp(r'^ica-\d+-[0-9a-f]{8}$')),
    );
    expect(store.cart, isEmpty);
    final restored = ShopStore(demo: true);
    await restored.init();
    expect(restored.orders.single['customer'], 'Ana');
  });
  test('No acepta un pedido vacío', () async {
    expect(() => ShopStore(demo: true).checkout('Ana', ''), throwsException);
  });
}
