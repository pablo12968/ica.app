import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';
import 'design.dart';
import 'shop.dart';
import 'sounds.dart';
import 'account.dart';

void main() => runApp(const IceCreamApp());

class IceCreamApp extends StatefulWidget {
  const IceCreamApp({super.key, this.store, this.sounds});
  final AppSounds? sounds;
  final ShopStore? store;
  @override
  State<IceCreamApp> createState() => _IceCreamAppState();
}

class _IceCreamAppState extends State<IceCreamApp> {
  late final ShopStore store;
  late final AppSounds sounds;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? ShopStore();
    sounds = widget.sounds ?? AppSounds();
    unawaited(sounds.init());
    if (widget.store == null) store.init();
  }

  @override
  void dispose() {
    if (widget.store == null) store.dispose();
    if (widget.sounds == null) sounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ice Cream App',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        bodyLarge: TextStyle(color: ink),
      ),
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: violet,
        primary: violet,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffe9e2ff),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: violet,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    home: ListenableBuilder(
      listenable: store,
      builder: (context, _) => store.demo || store.signedIn
          ? ShopHome(store: store, sounds: sounds)
          : AccountPage(store: store),
    ),
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.store, required this.sounds});
  final AppSounds sounds;
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
  void initState() {
    super.initState();
    name.text = widget.store.user?['name'] as String? ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (sending) return;
    if (!form.currentState!.validate()) {
      setState(() => error = null);
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await widget.store.checkout(name.text, note.text);
      unawaited(widget.sounds.play(UiSound.success));
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          sending = false;
          error = failure is OrderFailure
              ? failure.message
              : widget.store.demo
              ? 'No pudimos guardar el pedido de prueba. Vuelve a intentar; tu carrito se conserva.'
              : 'No pudimos confirmar el pedido. Revisa tu conexión y reintenta; el carrito se conserva.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pedido'),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: sending
              ? null
              : widget.sounds.action(() => Navigator.maybePop(context)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.storefront_outlined, size: 64),
              const SizedBox(height: 20),
              Text(
                widget.store.demo ? 'Un último detalle' : 'Revisa tu pedido',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.store.demo
                    ? 'Estás probando la app. El pedido es simulado.'
                    : 'El pedido quedará guardado en tu cuenta. No se realizará ningún cobro desde la app.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                enabled: !sending && widget.store.demo,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre de tu cuenta',
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
                  labelText: 'Nota del pedido (opcional)',
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
                onPressed: sending ? null : widget.sounds.action(submit),
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
