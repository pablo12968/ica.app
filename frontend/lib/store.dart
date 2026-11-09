import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class OrderFailure implements Exception {
  final String message;
  const OrderFailure(this.message);
}

class ShopStore extends ChangeNotifier {
  static const apiUrl = String.fromEnvironment('API_URL');
  final bool demo;
  bool get configured => baseUrl.isNotEmpty;
  String? _token;
  Map<String, dynamic>? user;
  bool get signedIn => user != null;
  bool get isAdmin => user?['role'] == 'admin';
  final http.Client _client;
  final String baseUrl;
  ShopStore({
    http.Client? client,
    String? serverUrl,
    this.demo = const bool.fromEnvironment('DEMO_MODE'),
  }) : _client = client ?? http.Client(),
       baseUrl = serverUrl ?? apiUrl;
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    if (baseUrl.isEmpty) {
      throw const OrderFailure('El servidor aún no está configurado.');
    }
    final uri = Uri.parse('$baseUrl/api/$path');
    final sessionToken = _token;
    final response =
        await (body == null
                ? _client.get(uri, headers: authHeaders)
                : _client.post(
                    uri,
                    headers: authHeaders,
                    body: jsonEncode(body),
                  ))
            .timeout(const Duration(seconds: 20));
    if (sessionToken != _token) {
      throw const OrderFailure('La sesión cambió. Vuelve a intentar.');
    }
    if (response.statusCode == 401 &&
        path != 'auth/login' &&
        path != 'auth/register') {
      _clearSession();
    }
    if (response.statusCode >= 400) {
      String message = 'No se pudo completar la solicitud.';
      try {
        message = (jsonDecode(response.body) as Map)['message'] as String;
      } catch (_) {}
      throw OrderFailure(message);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<void> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    final result = await request(
      'auth/${name == null ? 'login' : 'register'}',
      body: {
        'email': email.trim(),
        'password': password,
        if (name != null) 'name': name.trim(),
      },
    ) as Map<String, dynamic>;
    _clearSession();
    _token = result['token'] as String;
    user = result['user'] as Map<String, dynamic>;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      favorites =
          (_prefs!.getStringList('ica_${baseUrl}_${user!['id']}_favorites') ??
                  [])
              .map(int.parse)
              .toSet();
    } catch (_) {
      favorites = {};
    }
    notifyListeners();
    try {
      await refreshOrders();
    } catch (_) {
      storageWarning =
          'No se pudo cargar tu historial. Pulsa actualizar en Mis pedidos.';
    }
    await loadProducts();
  }

  Future<void> refreshOrders() async {
    final result = await request('orders') as List;
    orders = List<Map<String, dynamic>>.from(result);
    storageWarning = null;
    notifyListeners();
  }

  void _clearSession() {
    _token = null;
    user = null;
    orders = [];
    favorites = {};
    cart.clear();
    _requestId = null;
    _requestBody = null;
    storageWarning = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await request('auth/logout', body: {});
    _clearSession();
  }

  Future<void> recordActivity(String event) async {
    if (demo || !signedIn) return;
    try {
      await request('activity', body: {'event': event});
    } catch (_) {
      // Auxiliary activity must not block shopping; orders are recorded transactionally.
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  List<Product> products = [];
  final List<CartLine> cart = [];
  List<Map<String, dynamic>> orders = [];
  Set<int> favorites = {};
  bool loading = true;
  String? error;
  String? storageWarning;
  SharedPreferences? _prefs;
  int get total => cart.fold(0, (sum, line) => sum + line.total);
  int get count => cart.fold(0, (sum, line) => sum + line.quantity);

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final saved = _prefs!.getString('ica_${demo ? 'demo' : apiUrl}_orders');
      if (demo && saved != null) {
        orders = List<Map<String, dynamic>>.from(jsonDecode(saved) as List);
      }
      if (demo) {
        favorites = (_prefs!.getStringList('ica_favorites') ?? [])
            .map(int.parse)
            .toSet();
      }
    } catch (_) {
      storageWarning = 'No se pudo recuperar el historial local.';
    }
    await loadProducts();
  }

  Future<void> loadProducts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (demo) {
        products = List.of(demoProducts);
      } else {
        final response = await _client
            .get(Uri.parse('$baseUrl/api/products'))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) throw Exception();
        products = (jsonDecode(response.body) as List)
            .map((j) => Product.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      for (var i = cart.length - 1; i >= 0; i--) {
        final old = cart[i];
        final matches = products.where((p) => p.id == old.product.id);
        if (matches.isEmpty) {
          cart.removeAt(i);
          storageWarning =
              'Se retiró del carrito un producto que ya no está disponible.';
        } else {
          cart[i] = CartLine.custom(
            matches.first,
            old.size,
            old.selectedToppings,
            old.quantity,
          );
        }
      }
    } catch (_) {
      error = 'No pudimos cargar el catálogo. Comprueba la conexión con el servidor.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(int id) async {
    if (!favorites.add(id)) favorites.remove(id);
    if (!demo) {
      unawaited(
        recordActivity(
          favorites.contains(id) ? 'favorite_added' : 'favorite_removed',
        ),
      );
      try {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setStringList(
          'ica_${baseUrl}_${user!['id']}_favorites',
          favorites.map((id) => '$id').toList(),
        );
      } catch (_) {
        storageWarning = 'No se pudieron guardar los favoritos.';
      }
      notifyListeners();
      return;
    }
    notifyListeners();
    try {
      await _prefs?.setStringList(
        'ica_favorites',
        favorites.map((id) => '$id').toList(),
      );
    } catch (_) {
      storageWarning = 'No se pudieron guardar los favoritos.';
      notifyListeners();
    }
  }

  void add(Product product, String size, String topping) {
    final line = CartLine(product, size, topping);
    final index = cart.indexWhere((item) => item.key == line.key);
    if (index < 0) {
      cart.add(line);
    } else if (cart[index].quantity < 20) {
      cart[index].quantity++;
    }
    unawaited(recordActivity('cart_updated'));
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    line.quantity += delta;
    if (line.quantity <= 0) cart.remove(line);
    if (line.quantity > 20) line.quantity = 20;
    unawaited(recordActivity('cart_updated'));
    notifyListeners();
  }

  bool addCustomized(
    Product product,
    String size,
    Iterable<String> extras,
    int quantity,
  ) {
    if (!sizes.containsKey(size) ||
        quantity < 1 ||
        quantity > 20 ||
        extras.any((name) => !toppingCategories.containsKey(name))) {
      return false;
    }
    final line = CartLine.custom(product, size, extras, quantity);
    final index = cart.indexWhere((item) => item.key == line.key);
    if (index >= 0 && cart[index].quantity + quantity > 20) return false;
    if (index < 0) {
      cart.add(line);
    } else {
      cart[index].quantity += quantity;
    }
    unawaited(recordActivity('cart_updated'));
    notifyListeners();
    return true;
  }

  void remove(CartLine line) {
    cart.remove(line);
    unawaited(recordActivity('cart_updated'));
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    unawaited(recordActivity('cart_updated'));
    notifyListeners();
  }

  String? _requestId;
  String? _requestBody;
  Future<void> checkout(String customer, String note) async {
    if (!demo && !signedIn) {
      throw const OrderFailure('Inicia sesión para enviar tu pedido.');
    }
    if (cart.isEmpty) throw Exception('El carrito está vacío.');
    final items = cart
        .map(
          (line) => {
            ...line.toJson(),
            'name': line.product.name,
            'unitPrice': line.unitPrice,
          },
        )
        .toList();
    final body = jsonEncode({
      'customer': customer.trim(),
      'note': note.trim(),
      'expectedTotal': total,
      'items': cart.map((line) => line.toJson()).toList(),
    });
    if (_requestBody != body) {
      // A 32-bit shift becomes zero when compiled to JavaScript. Use two
      // 16-bit draws so web and native builds generate valid request IDs.
      final random = Random.secure();
      final suffix = List.generate(
        2,
        (_) => random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
      ).join();
      _requestId = 'ica-${DateTime.now().microsecondsSinceEpoch}-$suffix';
      _requestBody = body;
    }
    Map<String, dynamic> order;
    if (demo) {
      order = {
        'id': _requestId,
        'createdAt': DateTime.now().toIso8601String(),
        'total': total,
        'items': items,
        'status': 'Simulado',
        'customer': customer.trim(),
        'note': note.trim(),
      };
    } else {
      final sessionToken = _token;
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/orders'),
            headers: {...authHeaders, 'Idempotency-Key': _requestId!},
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (sessionToken != _token) {
        throw const OrderFailure(
          'La sesión cambió. Consulta el historial al volver a entrar.',
        );
      }
      if (response.statusCode != 201 && response.statusCode != 200) {
        if (response.statusCode == 401) _clearSession();
        String message =
            'No se confirmó el pedido. Comprueba la conexión y reintenta.';
        try {
          message =
              (jsonDecode(response.body) as Map<String, dynamic>)['message']
                  as String;
        } catch (_) {}
        throw OrderFailure(message);
      }
      order = jsonDecode(response.body) as Map<String, dynamic>;
    }
    final updatedOrders = [
      order,
      ...orders.where((old) => old['id'] != order['id']),
    ];
    if (!demo) {
      orders = updatedOrders;
      cart.clear();
      _requestId = null;
      _requestBody = null;
      notifyListeners();
      return;
    }
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final saved = await _prefs!.setString(
        'ica_${demo ? 'demo' : apiUrl}_orders',
        jsonEncode(updatedOrders),
      );
      if (!saved) throw StateError('History write was rejected');
      storageWarning = null;
    } catch (_) {
      if (demo) {
        throw const OrderFailure(
          'No pudimos guardar el historial en este dispositivo. '
          'Permite el almacenamiento del navegador y vuelve a intentar; '
          'tu carrito se conserva.',
        );
      }
      storageWarning = 'Pedido confirmado, pero no se pudo guardar el historial en este dispositivo.';
    }
    orders = updatedOrders;
    cart.clear();
    _requestId = null;
    _requestBody = null;
    notifyListeners();
  }
}
