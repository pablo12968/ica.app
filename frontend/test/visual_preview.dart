// Ejecutar con: flutter test test/visual_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models.dart';
import 'package:frontend/store.dart';
import 'package:frontend/sounds.dart';

void main() {
  testWidgets('Renderizar pantallas para revisión visual', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 940);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'ica_sound': false});
    final fonts = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final store = ShopStore(demo: true);
    await store.init();
    final sounds = AppSounds(playback: (_) async {});
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: IceCreamApp(store: store, sounds: sounds),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final asset in [
        'strawberry',
        'chocolate',
        'vanilla',
        'mango',
        'lime',
        'pistachio',
        'toppings-atlas',
        'toppings-hero',
      ]) {
        await precacheImage(
          AssetImage('assets/images/$asset.png'),
          tester.element(find.byType(Scaffold).first),
        );
      }
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../entrega/preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await capture('catalogo-amplio');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await capture('catalogo-movil');
    await tester.scrollUntilVisible(
      find.text('Fresa de temporada'),
      160,
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
    await capture('producto');
    await tester.tap(find.text('Personalizar toppings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir toppings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chispas de colores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chispas de chocolate'));
    await tester.pumpAndSettle();
    await capture('toppings');
    await tester.tap(find.text('Ver resumen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quitar Chispas de chocolate'));
    await tester.pumpAndSettle();
    await capture('resumen-toppings');
    await tester.tap(find.text('Agregar al carrito'));
    await tester.pumpAndSettle();
    expect(store.cart.single.selectedToppings, ['Chispas de colores']);
    expect(store.total, 300000);
    await tester.pumpAndSettle();
    store.add(demoProducts[1], 'Dos bolas', 'Chocolate');
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await capture('carrito');
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await capture('perfil');
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    sounds.dispose();
  });
}
