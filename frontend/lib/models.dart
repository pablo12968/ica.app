class Product {
  final int id;
  final String name, description, category;
  final int price;
  const Product(
    this.id,
    this.name,
    this.description,
    this.category,
    this.price,
  );
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    j['id'] as int,
    j['name'] as String,
    j['description'] as String? ?? '',
    j['category'] as String? ?? 'Helados',
    (num.parse('${j['price']}') * 100).round(),
  );
}

const demoProducts = [
  Product(
    1,
    'Fresa de temporada',
    'Cremoso helado con fresas y un toque de vainilla.',
    'Clásicos',
    250000,
  ),
  Product(
    2,
    'Chocolate intenso',
    'Cacao, textura suave y mucho chocolate.',
    'Clásicos',
    250000,
  ),
  Product(
    3,
    'Vainilla artesanal',
    'El clásico que combina con todo.',
    'Clásicos',
    250000,
  ),
  Product(
    4,
    'Mango tropical',
    'Sorbete refrescante de mango. Sin lácteos.',
    'Frutales',
    250000,
  ),
  Product(
    5,
    'Limón fresco',
    'Sorbete cítrico y ligero. Sin lácteos.',
    'Frutales',
    250000,
  ),
  Product(
    6,
    'Pistacho especial',
    'Helado cremoso con pistacho. Contiene frutos secos.',
    'Especiales',
    350000,
  ),
];

const sizes = {'Una bola': 0, 'Dos bolas': 100000, 'Tres bolas': 200000};
const toppings = {
  'Sin topping': 0,
  'Chocolate': 50000,
  'Galleta': 50000,
  'Chispas': 25000,
};
String money(int amount) {
  final whole = (amount ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  final cents = amount % 100;
  return '\$ $whole${cents == 0 ? '' : ',${cents.toString().padLeft(2, '0')}'} COP';
}

class CartLine {
  final Product product;
  final String size, topping;
  int quantity;
  CartLine(this.product, this.size, this.topping, [this.quantity = 1]);
  String get key => '${product.id}|$size|$topping';
  int get unitPrice => product.price + sizes[size]! + toppings[topping]!;
  int get total => unitPrice * quantity;
  Map<String, dynamic> toJson() => {
    'productId': product.id,
    'size': size,
    'topping': topping,
    'quantity': quantity,
  };
}
