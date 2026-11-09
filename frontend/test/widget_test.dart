import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/store.dart';
import 'package:frontend/sounds.dart';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit.ttf'));
    await loader.load();
  });
  testWidgets('Buscar, guardar un favorito, silenciar y vaciar el carrito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = ShopStore(demo: true);
    await store.init();
    final played = <UiSound>[];
    final sounds = AppSounds(playback: (sound) async => played.add(sound));
    addTearDown(sounds.dispose);
    await tester.pumpWidget(IceCreamApp(store: store, sounds: sounds));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mango');
    await tester.pumpAndSettle();
    expect(find.text('Fresa de temporada'), findsNothing);
    await tester.tap(find.text('Mango tropical'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorito'));
    await tester.pumpAndSettle();
    expect(store.favorites, contains(4));
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(sounds.enabled, isFalse);
    final count = played.length;
    store.add(store.products.first, 'Una bola', 'Sin topping');
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vaciar carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conservar'));
    await tester.pumpAndSettle();
    expect(store.cart, hasLength(1));
    await tester.tap(find.byTooltip('Vaciar carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();
    expect(store.cart, isEmpty);
    expect(played.length, count);
  });
  testWidgets('Catálogo, personalización, carrito y pedido simulado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = ShopStore(demo: true);
    await store.init();
    final sounds = AppSounds(playback: (_) async {});
    addTearDown(sounds.dispose);
    await tester.pumpWidget(IceCreamApp(store: store, sounds: sounds));
    await tester.pumpAndSettle();
    expect(find.text('Ice Cream App'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fresa de temporada'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fresa de temporada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalizar toppings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir toppings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chispas de colores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chispas de chocolate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resumen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quitar Chispas de chocolate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar al carrito'));
    await tester.pumpAndSettle();
    expect(store.cart.single.selectedToppings, ['Chispas de colores']);
    expect(store.total, 300000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Carrito de compras'), findsOneWidget);
    await tester.ensureVisible(find.text('Continuar con el pedido →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con el pedido →'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 2 caracteres.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.ensureVisible(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simular pedido'));
    await tester.pumpAndSettle();
    expect(store.orders.single['customer'], 'Ana');
    expect(store.cart, isEmpty);
  });
}
