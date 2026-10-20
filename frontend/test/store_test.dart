import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/store.dart';
import 'package:frontend/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Agrupa configuraciones iguales y calcula extras por unidad', () {
    final store = ShopStore();
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
    final store = ShopStore();
    await store.init();
    store.add(demoProducts.first, 'Una bola', 'Sin topping');
    await store.checkout('Ana', 'Gracias');
    expect(store.orders.single['status'], 'Simulado');
    expect(store.orders.single['total'], 250000);
    expect(store.cart, isEmpty);
    final restored = ShopStore();
    await restored.init();
    expect(restored.orders.single['customer'], 'Ana');
  });
  test('No acepta un pedido vacío', () async {
    expect(() => ShopStore().checkout('Ana', ''), throwsException);
  });
}
