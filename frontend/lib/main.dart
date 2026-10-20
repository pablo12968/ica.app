import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';

void main() => runApp(const IceCreamApp());

class IceCreamApp extends StatefulWidget {
  const IceCreamApp({super.key, this.store});
  final ShopStore? store;
  @override
  State<IceCreamApp> createState() => _IceCreamAppState();
}

class _IceCreamAppState extends State<IceCreamApp> {
  late final ShopStore store;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? ShopStore();
    if (widget.store == null) store.init();
  }

  @override
  void dispose() {
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ice Cream App',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfffffaf4),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffab3e58),
        surface: const Color(0xfffffaf4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfffffaf4),
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    home: ShopHome(store: store),
  );
}

class ShopHome extends StatefulWidget {
  const ShopHome({super.key, required this.store});
  final ShopStore store;
  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  int page = 0;
  String search = '', category = 'Todos';
  bool onlyFavorites = false;
  ShopStore get store => widget.store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.icecream_rounded),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Ice Cream App',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Información',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Ice Cream App',
              applicationVersion: '1.0.0',
              children: [
                Text(
                  store.demo
                      ? 'Modo demostración: catálogo de ejemplo y pedidos simulados guardados en este dispositivo. No se envían pedidos ni se realizan cobros.'
                      : 'Pedidos para recoger en tienda. Pago al recoger. El historial se guarda en este dispositivo.',
                ),
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                if (store.demo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: const Color(0xfff7e9cd),
                    child: const Text(
                      'DEMO · Explora y prueba pedidos sin cobros',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (store.storageWarning != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      store.storageWarning!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: switch (page) {
                    0 => catalog(),
                    1 => cart(),
                    _ => history(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Helados',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${store.count}'),
              isLabelVisible: store.count > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Mis pedidos',
          ),
        ],
      ),
    ),
  );

  Widget catalog() {
    if (store.loading) return const Center(child: CircularProgressIndicator());
    if (store.error != null) {
      return empty(
        Icons.cloud_off,
        store.error!,
        action: FilledButton(
          onPressed: store.loadProducts,
          child: const Text('Reintentar'),
        ),
      );
    }
    final visible = store.products
        .where(
          (p) =>
              (category == 'Todos' || p.category == category) &&
              p.name.toLowerCase().contains(search.toLowerCase().trim()) &&
              (!onlyFavorites || store.favorites.contains(p.id)),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: store.loadProducts,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xfff7dce2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HECHO PARA DISFRUTAR',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Un poquito de\nfelicidad en cada bola.',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 12),
                Text('Elige tu sabor, hazlo tuyo y disfruta. 🍦'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: const InputDecoration(
              hintText: 'Busca tu sabor favorito',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                ['Todos', ...store.products.map((p) => p.category).toSet()]
                    .map(
                      (name) => ChoiceChip(
                        label: Text(name),
                        selected: category == name,
                        onSelected: (_) => setState(() => category = name),
                      ),
                    )
                    .toList(),
          ),
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Nuestros sabores',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              FilterChip(
                label: const Text('Favoritos'),
                avatar: const Icon(Icons.favorite_border, size: 16),
                selected: onlyFavorites,
                onSelected: (v) => setState(() => onlyFavorites = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No hay sabores que coincidan. Prueba otra búsqueda.',
              ),
            ),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: visible
                  .map(
                    (product) => SizedBox(
                      width: box.maxWidth >= 550
                          ? (box.maxWidth - 24) / 3
                          : (box.maxWidth - 12) / 2,
                      child: productCard(product),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Precios del catálogo de la tienda. Recogida en tienda.\nConsulta al personal sobre alérgenos y contaminación cruzada.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget productCard(Product p) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => customize(p),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: [
                  const Color(0xfffce0e7),
                  const Color(0xffeadaca),
                  const Color(0xfff8efd5),
                  const Color(0xffffe5b2),
                  const Color(0xffe6efc7),
                  const Color(0xffdcebcf),
                ][(p.id - 1).abs() % 6],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.icecream_rounded,
                      size: 66,
                      color: Color(0xff99596c),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: store.favorites.contains(p.id)
                          ? 'Quitar de favoritos'
                          : 'Añadir a favoritos',
                      onPressed: () => store.toggleFavorite(p.id),
                      icon: Icon(
                        store.favorites.contains(p.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Desde ${money(p.price)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Text('Personalizar'),
                Spacer(),
                Icon(Icons.add_circle_outline, size: 22),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> customize(Product p) async {
    String size = sizes.keys.first, topping = toppings.keys.first;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(p.description),
              const SizedBox(height: 24),
              const Text(
                'Tu tamaño',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: sizes.entries
                    .map(
                      (e) => ChoiceChip(
                        label: Text('${e.key}\n${money(p.price + e.value)}'),
                        selected: size == e.key,
                        onSelected: (_) => update(() => size = e.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'El toque final',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: toppings.entries
                    .map(
                      (e) => ChoiceChip(
                        label: Text(
                          '${e.key}${e.value > 0 ? ' +${money(e.value)}' : ''}',
                        ),
                        selected: topping == e.key,
                        onSelected: (_) => update(() => topping = e.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    store.add(p, size, topping);
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('${p.name} añadido al carrito'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    'Añadir · ${money(p.price + sizes[size]! + toppings[topping]!)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cart() {
    if (store.cart.isEmpty) {
      return empty(
        Icons.shopping_bag_outlined,
        'Tu próximo helado te espera',
        action: FilledButton(
          onPressed: () => setState(() => page = 0),
          child: const Text('Explorar sabores'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Tu bolsa de felicidad',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        ...store.cart.map(
          (line) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${line.size} · ${line.topping}'),
                  Row(
                    children: [
                      Text(
                        money(line.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Reducir cantidad',
                        onPressed: () => store.changeQuantity(line, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${line.quantity}'),
                      IconButton(
                        tooltip: 'Aumentar cantidad',
                        onPressed: line.quantity >= 20
                            ? null
                            : () => store.changeQuantity(line, 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontSize: 22)),
            Text(
              money(store.total),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          store.demo
              ? 'Este pedido será una simulación. No se envía a ninguna tienda.'
              : 'Para recoger en tienda. Pagas al recoger; no se realiza ningún cobro en la app.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () async {
            final done = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => CheckoutPage(store: store)),
            );
            if (done == true && mounted) setState(() => page = 2);
          },
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Continuar con el pedido'),
          ),
        ),
      ],
    );
  }

  Widget history() => store.orders.isEmpty
      ? empty(
          Icons.receipt_long_outlined,
          'Aquí verás tus pedidos',
          action: const Text('Haz tu primer pedido desde el catálogo.'),
        )
      : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Mis pedidos',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const Text('Historial guardado en este dispositivo'),
            const SizedBox(height: 16),
            ...store.orders.map(
              (order) => Card(
                child: ExpansionTile(
                  title: Text(
                    money((order['total'] as num).round()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${order['status']} · ${DateTime.tryParse('${order['createdAt']}')?.toLocal().toString().substring(0, 16) ?? ''}',
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Referencia: ${order['id']}'),
                    const SizedBox(height: 8),
                    Text('Recoge: ${order['customer']}'),
                    ...(order['items'] as List).map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '${item['quantity']} × ${item['name']}\n${item['size']} · ${item['topping']}',
                        ),
                      ),
                    ),
                    if ('${order['note'] ?? ''}'.isNotEmpty)
                      Text('Nota: ${order['note']}'),
                    if (store.demo)
                      const Text('Pedido simulado · no requiere recogida'),
                  ],
                ),
              ),
            ),
          ],
        );

  Widget empty(IconData icon, String title, {Widget? action}) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 70, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ?action,
        ],
      ),
    ),
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.store});
  final ShopStore store;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), note = TextEditingController();
  bool sending = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || sending) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await widget.store.checkout(name.text, note.text);
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          sending = false;
          error = failure is OrderFailure ? failure.message : 'No pudimos confirmar el pedido. Revisa tu conexión y reintenta; el carrito se conserva.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.storefront_outlined, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Recogida en tienda',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.store.demo
                    ? 'Estás probando la app. El pedido es simulado.'
                    : 'El pedido se enviará a la tienda conectada. Pago al recoger.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                enabled: !sending,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre para recoger',
                ),
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? 'Escribe al menos 2 caracteres.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: note,
                enabled: !sending,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nota para la tienda (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Total: ${money(widget.store.total)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: sending ? null : submit,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.store.demo
                              ? 'Simular pedido'
                              : 'Enviar pedido',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
