import 'dart:async';

import 'package:flutter/material.dart';

import 'design.dart';
import 'toppings_page.dart';
import 'models.dart';
import 'store.dart';
import 'sounds.dart';
import 'account.dart';
import 'main.dart' show CheckoutPage;

class ShopHome extends StatefulWidget {
  const ShopHome({super.key, required this.store, required this.sounds});
  final ShopStore store;
  final AppSounds sounds;
  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  int page = 0;
  String category = 'Todos', search = '';
  bool favoritesOnly = false;
  final searchController = TextEditingController();
  ShopStore get store => widget.store;
  AppSounds get sounds => widget.sounds;
  void navigate(int value) {
    if (value == 3 && !store.demo) {
      unawaited(
        store.refreshOrders().catchError((Object e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e is OrderFailure
                      ? e.message
                      : 'No se pudo actualizar el historial.',
                ),
              ),
            );
          }
        }),
      );
    }
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    unawaited(sounds.play(UiSound.tap));
    setState(() => page = value);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([store, sounds]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 20,
        leading: page == 0
            ? null
            : IconButton(
                tooltip: 'Volver al inicio',
                onPressed: () => navigate(0),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: page == 0
            ? Row(
                children: [
                  Container(
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xfff2e6ff),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.icecream_rounded,
                      color: violet,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Ice Cream '),
                              TextSpan(
                                text: 'App',
                                style: TextStyle(color: violet),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                          ),
                        ),
                        Text(
                          'Tu momento más dulce',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Text(
                [
                  '',
                  'Buscar sabores',
                  'Carrito de compras',
                  'Mis pedidos',
                  'Mi perfil',
                ][page],
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          if (page == 0)
            IconButton(
              tooltip: 'Buscar sabores',
              onPressed: () => navigate(1),
              icon: const Icon(Icons.search_rounded),
            ),
          if (page == 2 && store.cart.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar carrito',
              onPressed: sounds.action(clearCart),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          if (page == 0)
            IconButton(
              tooltip: 'Sonidos y perfil',
              onPressed: () => navigate(4),
              icon: const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xfff0e5ff),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: violet,
                  size: 22,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                if (store.storageWarning != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      store.storageWarning!,
                      style: const TextStyle(color: muted),
                    ),
                  ),
                Expanded(
                  child: switch (page) {
                    0 || 1 => catalog(),
                    2 => cart(),
                    3 => history(),
                    _ => profile(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0d562a89), blurRadius: 20)],
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: page,
          onDestinationSelected: navigate,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Helados',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              label: 'Buscar',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: store.count > 0,
                label: Text('${store.count}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: 'Carrito',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Mis pedidos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    ),
  );

  bool matchesCategory(Product p) => switch (category) {
    'Todos' => true,
    'Chocolate' => p.name.toLowerCase().contains('chocolate'),
    'Cremosos' =>
      p.category == 'Clásicos' && !p.name.toLowerCase().contains('chocolate'),
    _ => p.category == category,
  };

  Widget catalog() {
    if (store.loading) return const Center(child: CircularProgressIndicator());
    if (store.error != null) {
      return empty(
        Icons.cloud_off_rounded,
        'No pudimos cargar los sabores',
        store.error!,
        action: FilledButton(
          onPressed: sounds.action(() => store.loadProducts()),
          child: const Text('Reintentar'),
        ),
      );
    }
    final visible = store.products
        .where(
          (p) =>
              matchesCategory(p) &&
              p.name.toLowerCase().contains(search.toLowerCase().trim()) &&
              (!favoritesOnly || store.favorites.contains(p.id)),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: store.loadProducts,
      child: ListView(
        key: PageStorageKey('catalog-$page'),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          if (page == 0) hero(),
          if (page == 1) ...[
            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                hintText: 'Encuentra tu sabor favorito',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: sounds.action(() {
                          searchController.clear();
                          setState(() => search = '');
                        }),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  ('Todos', Icons.grid_view_rounded),
                  ('Frutales', Icons.local_florist_rounded),
                  ('Chocolate', Icons.bakery_dining_rounded),
                  ('Cremosos', Icons.icecream_rounded),
                  ('Especiales', Icons.star_rounded),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: Semantics(
                      selected: category == item.$1,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: sounds.action(
                          () => setState(() => category = item.$1),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 91,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: category == item.$1
                                ? const Color(0xffeee3ff)
                                : const Color(0xfff4f3f7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: category == item.$1
                                  ? const Color(0xffd9bfff)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                item.$2,
                                size: 27,
                                color: category == item.$1
                                    ? violet
                                    : const Color(0xffd76f9d),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.$1,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: category == item.$1
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: category == item.$1 ? violet : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nuestros sabores',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: favoritesOnly
                    ? 'Ver todos los sabores'
                    : 'Ver favoritos',
                onPressed: sounds.action(
                  () => setState(() => favoritesOnly = !favoritesOnly),
                ),
                icon: Icon(
                  favoritesOnly ? Icons.favorite : Icons.favorite_border,
                  color: violet,
                ),
              ),
              TextButton(
                onPressed: sounds.action(() {
                  searchController.clear();
                  setState(() {
                    search = '';
                    category = 'Todos';
                    favoritesOnly = false;
                  });
                }),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No encontramos sabores. Prueba otra categoría o búsqueda.',
              ),
            ),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 580
                  ? 3
                  : box.maxWidth >= 290
                  ? 2
                  : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final p in visible)
                    SizedBox(
                      width: (box.maxWidth - 12 * (columns - 1)) / columns,
                      child: productCard(p),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            store.demo
                ? 'Versión de prueba · Pedidos simulados, sin cobros.\nImágenes ilustrativas.'
                : 'Pide con tu cuenta. Imágenes ilustrativas.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, height: 1.6, color: muted),
          ),
        ],
      ),
    );
  }

  Widget hero() => ClipRRect(
    borderRadius: BorderRadius.circular(27),
    child: LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth > 600;
        return Container(
          height: wide ? 310 : 270,
          color: const Color(0xfff9e4fa),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: box.maxWidth * .61,
                child: Image.asset(
                  'assets/images/strawberry.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xfffae8ff),
                        const Color(0xfffae8ff).withValues(alpha: .96),
                        const Color(0xfffae8ff).withValues(alpha: 0),
                      ],
                      stops: const [0, .40, .78],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 30 : 20),
                child: SizedBox(
                  width: box.maxWidth * .58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'La felicidad\ntiene '),
                            TextSpan(
                              text: 'sabor',
                              style: TextStyle(color: violet),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: wide ? 43 : 29,
                          height: 1.06,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Descubre tu favorito y\ncrea una combinación única.',
                        style: TextStyle(
                          fontSize: wide ? 16 : 12,
                          color: const Color(0xff686078),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => navigate(1),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        child: const Text(
                          'Explorar sabores →',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget productCard(Product p) => SoftPanel(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: sounds.action(() => openProduct(p)),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(p),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: store.favorites.contains(p.id)
                          ? 'Quitar de favoritos'
                          : 'Añadir a favoritos',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .94),
                        minimumSize: const Size(38, 38),
                      ),
                      onPressed: sounds.action(
                        () => store.toggleFavorite(p.id),
                      ),
                      icon: Icon(
                        store.favorites.contains(p.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: store.favorites.contains(p.id)
                            ? const Color(0xffff5a88)
                            : muted,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Desde ${money(p.price)}',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Personalizar ${p.name}',
                      onPressed: sounds.action(() => openProduct(p)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: const Icon(
                        Icons.add_circle,
                        color: violet,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> openProduct(Product product) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ProductPage(product: product, store: store, sounds: sounds),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} añadido al carrito'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () => navigate(2),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> clearCart() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar el carrito?'),
        content: const Text('Se quitarán los helados que has seleccionado.'),
        actions: [
          TextButton(
            onPressed: sounds.action(() => Navigator.pop(context, false)),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: sounds.action(() => Navigator.pop(context, true)),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (clear == true) store.clearCart();
  }

  Widget cart() {
    if (store.cart.isEmpty) {
      return empty(
        Icons.shopping_cart_outlined,
        'Tu próximo helado te espera',
        'Elige un sabor y prepáralo a tu gusto.',
        action: FilledButton(
          onPressed: () => navigate(0),
          child: const Text('Explorar sabores'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final line in store.cart)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftPanel(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 74,
                      height: 90,
                      child: ProductPhoto(line.product),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${line.size} · ${line.topping}',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          money(line.total),
                          style: const TextStyle(
                            color: violet,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        quantityControls(
                          line.quantity,
                          () => store.changeQuantity(line, -1),
                          line.quantity < 20
                              ? () => store.changeQuantity(line, 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar ${line.product.name}',
                    onPressed: sounds.action(() => store.remove(line)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        SoftPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 14,
                runSpacing: 8,
                children: [
                  Text(
                    'Total (${store.count} productos)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    money(store.total),
                    style: const TextStyle(
                      color: violet,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: sounds.action(() async {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  final done = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutPage(store: store, sounds: sounds),
                    ),
                  );
                  if (done == true && mounted) setState(() => page = 3);
                }),
                child: const Text('Continuar con el pedido →'),
              ),
              const SizedBox(height: 12),
              Text(
                store.demo
                    ? 'Pedido simulado · no se realizan cobros ni envíos.'
                    : 'Tu pedido quedará guardado en tu cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget quantityControls(int value, VoidCallback minus, VoidCallback? plus) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Reducir cantidad',
            onPressed: sounds.action(minus),
            icon: const Icon(Icons.remove_circle_outline, size: 23),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            tooltip: 'Aumentar cantidad',
            onPressed: plus == null ? null : sounds.action(plus),
            icon: const Icon(Icons.add_circle_outline, size: 23, color: violet),
          ),
        ],
      );

  Widget history() {
    if (store.orders.isEmpty) {
      return empty(
        Icons.receipt_long_rounded,
        'Aquí empieza una dulce historia',
        'Tus pedidos aparecerán aquí cuando completes el primero.',
        action: FilledButton(
          onPressed: () => navigate(0),
          child: const Text('Elegir mi primer helado'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          store.demo
              ? 'Guardados en este dispositivo'
              : 'Guardados en tu cuenta',
          style: const TextStyle(color: muted),
        ),
        if (!store.demo)
          TextButton.icon(
            onPressed: () => navigate(3),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar pedidos'),
          ),
        const SizedBox(height: 16),
        for (final order in store.orders)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SoftPanel(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                onExpansionChanged: (_) => unawaited(sounds.play(UiSound.tap)),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Container(
                  width: 46,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xfff4eaff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.icecream_rounded, color: violet),
                ),
                title: Text(
                  money((order['total'] as num).round()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderDate('${order['createdAt']}'),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${order['status']} · ${(order['items'] as List).length} sabores',
                      style: const TextStyle(
                        color: violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.all(18),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para: ${order['customer']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final item in order['items'] as List)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        '${item['quantity']} × ${item['name']}\n${item['size']} · ${item['topping']}',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  if ('${order['note'] ?? ''}'.isNotEmpty)
                    Text('Nota: ${order['note']}'),
                  const Divider(),
                  SelectableText(
                    'Referencia: ${order['id']}',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                  if (store.demo)
                    const Text(
                      'Simulación · no requiere recogida',
                      style: TextStyle(fontSize: 12, color: violet),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String orderDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    return date == null
        ? ''
        : '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      SoftPanel(
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xfff0e4ff),
              child: Icon(
                Icons.person_outline_rounded,
                color: violet,
                size: 42,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tu rincón más dulce',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              store.user?['name'] as String? ?? 'Tu cuenta',
              style: const TextStyle(color: muted),
            ),
            if (store.user != null) Text('${store.user!['email']}'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (!store.demo) ...[
        if (store.isAdmin)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Administración'),
            subtitle: const Text('Usuarios, pedidos y actividad'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => AdminPage(store: store)),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: () async {
            try {
              await store.logout();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e is OrderFailure
                          ? e.message
                          : 'No se pudo cerrar sesión. Revisa tu conexión.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ],
      SoftPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Sonidos de la app'),
              subtitle: const Text('Toques suaves y confirmaciones'),
              secondary: Icon(
                sounds.enabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                color: violet,
              ),
              value: sounds.enabled,
              onChanged: (value) async {
                await sounds.setEnabled(value);
                if (value) unawaited(sounds.play(UiSound.tap));
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: violet),
              title: const Text('Mis favoritos'),
              trailing: Text('${store.favorites.length}'),
              onTap: sounds.action(
                () => setState(() {
                  favoritesOnly = true;
                  category = 'Todos';
                  search = '';
                  searchController.clear();
                  page = 0;
                }),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: violet),
              title: const Text('Mis pedidos'),
              trailing: Text('${store.orders.length}'),
              onTap: () => navigate(3),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hecha para disfrutar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              store.demo
                  ? 'Estás usando la versión de prueba. Los pedidos se simulan y permanecen en tu dispositivo. No se envían a una tienda ni generan cobros.'
                  : 'Tus pedidos se guardan en tu cuenta. Puedes consultarlos al iniciar sesión desde otro dispositivo. La app no realiza cobros.',
              style: const TextStyle(color: muted, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Consulta al personal sobre alérgenos antes de consumir un producto real.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Text(
              'Ice Cream App · 1.1.0',
              style: TextStyle(color: violet, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );

  Widget empty(
    IconData icon,
    String title,
    String description, {
    Widget? action,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: const BoxDecoration(
              color: Color(0xfff0e6ff),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: violet, size: 52),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.6),
          ),
          const SizedBox(height: 24),
          ?action,
        ],
      ),
    ),
  );
}

class ProductPage extends StatefulWidget {
  const ProductPage({
    super.key,
    required this.product,
    required this.store,
    required this.sounds,
  });
  final Product product;
  final ShopStore store;
  final AppSounds sounds;
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String size = sizes.keys.first;
  int quantity = 1;
  int get unitPrice => widget.product.price + sizes[size]!;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height < 700 ? 230 : 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductPhoto(widget.product),
                      Positioned(
                        top: 12,
                        left: 14,
                        child: IconButton.filledTonal(
                          tooltip: 'Volver',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: widget.sounds.action(
                            () => Navigator.pop(context),
                          ),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 14,
                        child: IconButton.filledTonal(
                          tooltip: 'Favorito',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: widget.sounds.action(
                            () =>
                                widget.store.toggleFavorite(widget.product.id),
                          ),
                          icon: Icon(
                            widget.store.favorites.contains(widget.product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: violet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(unitPrice),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: violet,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.description,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tamaño',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, box) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in sizes.entries)
                              SizedBox(
                                width: box.maxWidth < 290
                                    ? box.maxWidth
                                    : (box.maxWidth - 16) / 3,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: widget.sounds.action(
                                    () => setState(() => size = entry.key),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: size == entry.key
                                          ? const Color(0xfff6efff)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: size == entry.key
                                            ? violet
                                            : const Color(0xffe8e5ef),
                                        width: size == entry.key ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.icecream_rounded,
                                          size: 30,
                                          color: size == entry.key
                                              ? const Color(0xffff7ca6)
                                              : const Color(0xffdec8da),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          money(
                                            widget.product.price + entry.value,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: size == entry.key
                                                ? violet
                                                : muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Reducir cantidad',
                            onPressed: quantity > 1
                                ? widget.sounds.action(
                                    () => setState(() => quantity--),
                                  )
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Aumentar cantidad',
                            onPressed: quantity < 20
                                ? widget.sounds.action(
                                    () => setState(() => quantity++),
                                  )
                                : null,
                            icon: const Icon(
                              Icons.add_circle,
                              color: violet,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: FilledButton.icon(
            onPressed: () async {
              widget.sounds.action(() {})();
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ToppingsPage(
                    product: widget.product,
                    size: size,
                    quantity: quantity,
                    store: widget.store,
                    sounds: widget.sounds,
                  ),
                ),
              );
              if (added == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Personalizar toppings'),
          ),
        ),
      ),
    ),
  );
}
