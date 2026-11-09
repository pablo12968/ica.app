import 'package:flutter/material.dart';

import 'design.dart';
import 'models.dart';
import 'sounds.dart';
import 'store.dart';

/// Displays one cell of the locally bundled photographic atlas.
class ToppingPhoto extends StatelessWidget {
  const ToppingPhoto(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) {
    final index = toppingCategories.keys.toList().indexOf(name);
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          return Center(
            child: SizedBox.square(
              dimension: side,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: side * 3,
                  maxHeight: side * 3,
                  alignment: Alignment((index % 3) - 1.0, (index ~/ 3) - 1.0),
                  child: Image.asset(
                    'assets/images/toppings-atlas.png',
                    width: side * 3,
                    height: side * 3,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ToppingsPage extends StatefulWidget {
  const ToppingsPage({
    super.key,
    required this.product,
    required this.size,
    required this.quantity,
    required this.store,
    required this.sounds,
  });
  final Product product;
  final String size;
  final int quantity;
  final ShopStore store;
  final AppSounds sounds;
  @override
  State<ToppingsPage> createState() => _ToppingsPageState();
}

class _ToppingsPageState extends State<ToppingsPage> {
  int step = 0;
  String category = 'Todos', query = '';
  final selected = <String>{};
  int get base => widget.product.price + sizes[widget.size]!;
  int get unit =>
      base + selected.fold<int>(0, (sum, name) => sum + toppings[name]!);
  void toggle(String name) => widget.sounds.action(
    () => setState(() {
      if (!selected.add(name)) selected.remove(name);
    }),
    UiSound.tap,
  )();
  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  Widget heading(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
  );
  Widget photo() => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: SizedBox(
      height: 270,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/toppings-hero.png', fit: BoxFit.cover),
          const Positioned(
            bottom: 8,
            right: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xddffffff),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Imagen de inspiración',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget progress() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final entry in ['Sabor', 'Toppings', 'Resumen'].asMap().entries)
          Column(
            children: [
              CircleAvatar(
                backgroundColor: entry.key == (step == 2 ? 2 : 1)
                    ? violet
                    : const Color(0xfff2e8ff),
                foregroundColor: entry.key == (step == 2 ? 2 : 1)
                    ? Colors.white
                    : violet,
                child: Icon(
                  [
                    Icons.icecream_outlined,
                    Icons.auto_awesome,
                    Icons.shopping_bag_outlined,
                  ][entry.key],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.value,
                style: TextStyle(
                  color: entry.key == (step == 2 ? 2 : 1) ? violet : muted,
                ),
              ),
            ],
          ),
      ],
    ),
  );
  Widget intro() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      progress(),
      const SizedBox(height: 14),
      Center(child: heading('¡Agrega tus toppings!')),
      const SizedBox(height: 8),
      const Text(
        'Dale un toque especial a tu helado',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 17),
      ),
      const SizedBox(height: 24),
      photo(),
      const SizedBox(height: 16),
      SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${widget.size} · ${widget.quantity} ${widget.quantity == 1 ? 'helado' : 'helados'}',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige los extras que más te gusten. También puedes continuar sin toppings.',
            ),
          ],
        ),
      ),
    ],
  );
  Widget catalog() {
    final names = toppingCategories.keys
        .where(
          (name) =>
              (category == 'Todos' || toppingCategories[name] == category) &&
              name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar topping',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final name in [
                        'Todos',
                        'Salsas',
                        'Frutas',
                        'Dulces',
                        'Galletas',
                        'Frutos secos',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: category == name,
                            onSelected: (_) => widget.sounds.action(
                              () => setState(() => category = name),
                            )(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${selected.length} seleccionados · Precio por helado',
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ),
        if (names.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No encontramos ese topping. Prueba otra búsqueda.'),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.crossAxisExtent > 600 ? 3 : 2,
                mainAxisExtent: 235,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final name = names[index], active = selected.contains(name);
                return Semantics(
                  selected: active,
                  button: true,
                  label: '$name, ${money(toppings[name]!)}',
                  child: Material(
                    color: active ? const Color(0xfff4ebff) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: active ? violet : const Color(0xffeee8f1),
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => toggle(name),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ColoredBox(
                              color: const Color(0xffffd9df),
                              child: ToppingPhoto(name),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: Text(
                              name,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    money(toppings[name]!),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Icon(
                                  active
                                      ? Icons.check_circle
                                      : Icons.add_circle,
                                  color: violet,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: names.length),
            ),
          ),
        ),
      ],
    );
  }

  Widget summary() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      if (selected.isNotEmpty)
        SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selected.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final name = selected.elementAt(index);
              return SizedBox(
                width: 108,
                child: Stack(
                  children: [
                    SoftPanel(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(height: 78, child: ToppingPhoto(name)),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton.filledTonal(
                        tooltip: 'Quitar $name',
                        onPressed: () => toggle(name),
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      const SizedBox(height: 12),
      photo(),
      const SizedBox(height: 14),
      SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de tu helado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              '${widget.product.name} · ${widget.size}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            priceRow('Helado base', base),
            for (final name in selected) priceRow(name, toppings[name]!),
            if (selected.isEmpty)
              const Text(
                'Sin toppings adicionales',
                style: TextStyle(color: muted),
              ),
            const Divider(height: 24),
            priceRow('Por helado', unit),
            const SizedBox(height: 6),
            Text('Cantidad: ${widget.quantity}'),
            TextButton(
              onPressed: widget.sounds.action(() => setState(() => step = 1)),
              child: const Text('Editar toppings'),
            ),
          ],
        ),
      ),
    ],
  );
  Widget priceRow(String label, int price) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Text(money(price)),
      ],
    ),
  );
  void next() {
    if (step < 2) {
      widget.sounds.action(() => setState(() => step++))();
      return;
    }
    if (!widget.store.addCustomized(
      widget.product,
      widget.size,
      selected,
      widget.quantity,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Máximo 20 unidades por combinación. Ajusta el carrito.',
          ),
        ),
      );
      return;
    }
    widget.sounds.action(() => Navigator.pop(context, true), UiSound.add)();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) back();
    },
    child: Scaffold(
      backgroundColor: const Color(0xfffff5fa),
      appBar: AppBar(
        backgroundColor: const Color(0xfffff5fa),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: widget.sounds.action(back),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          ['Personaliza tu helado', 'Toppings', 'Toppings seleccionados'][step],
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: [intro, catalog, summary][step](),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step == 2
                          ? 'Total · ${widget.quantity} ${widget.quantity == 1 ? 'helado' : 'helados'}'
                          : 'Helado actual',
                      style: const TextStyle(color: muted),
                    ),
                  ),
                  Text(
                    money(unit * widget.quantity),
                    style: const TextStyle(
                      color: violet,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: next,
                icon: Icon(
                  step == 2
                      ? Icons.shopping_cart_outlined
                      : Icons.arrow_forward,
                ),
                label: Text(
                  [
                    'Elegir toppings',
                    'Ver resumen',
                    'Agregar al carrito',
                  ][step],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
