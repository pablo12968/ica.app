import 'dart:convert';
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
  bool get demo => apiUrl.isEmpty;
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
      if (saved != null) {
        orders = List<Map<String, dynamic>>.from(jsonDecode(saved) as List);
      }
      favorites = (_prefs!.getStringList('ica_favorites') ?? [])
          .map(int.parse)
          .toSet();
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
        final response = await http
            .get(Uri.parse('$apiUrl/api/products'))
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
          cart[i] = CartLine(
            matches.first,
            old.size,
            old.topping,
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
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    line.quantity += delta;
    if (line.quantity <= 0) cart.remove(line);
    if (line.quantity > 20) line.quantity = 20;
    notifyListeners();
  }

  String? _requestId;
  String? _requestBody;
  Future<void> checkout(String customer, String note) async {
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
      _requestId =
          'ica-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
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
      final response = await http
          .post(
            Uri.parse('$apiUrl/api/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': _requestId!,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201 && response.statusCode != 200) {
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
    orders.insert(0, order);
    cart.clear();
    _requestId = null;
    _requestBody = null;
    try {
      if (_prefs == null) throw Exception();
      await _prefs!.setString(
        'ica_${demo ? 'demo' : apiUrl}_orders',
        jsonEncode(orders),
      );
    } catch (_) {
      storageWarning = 'Pedido confirmado, pero no se pudo guardar el historial en este dispositivo.';
    }
    notifyListeners();
  }
}
