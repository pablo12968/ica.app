export const sizes: Record<string, number> = { 'Una bola': 0, 'Dos bolas': 100000, 'Tres bolas': 200000 };
export const toppings: Record<string, number> = { 'Sin topping': 0, 'Chocolate': 50000, 'Galleta': 50000, 'Chispas': 25000, 'Chispas de colores': 50000, 'Chispas de chocolate': 50000, 'Oreo triturada': 80000, 'Galleta con chocolate': 80000, 'Dulces de chocolate': 80000, 'Almendras': 70000, 'Fresa fresca': 70000, 'Banano': 70000, 'Salsa de chocolate': 50000 };
export class ValidationError extends Error {}
export function validateOrder(body: any) {
  if (!body || !Number.isSafeInteger(body.expectedTotal) || body.expectedTotal < 0) throw new ValidationError('Total no válido.');
  if (!body || typeof body.customer !== 'string' || body.customer.trim().length < 2 || body.customer.trim().length > 80) throw new ValidationError('Nombre no válido.');
  if (body.note != null && (typeof body.note !== 'string' || body.note.length > 300)) throw new ValidationError('Nota no válida.');
  if (!Array.isArray(body.items) || body.items.length < 1 || body.items.length > 50) throw new ValidationError('El pedido debe tener entre 1 y 50 líneas.');
  const items: Array<{ productId: number; quantity: number; size: string; topping: string; toppings: string[] }> = body.items.map((item: any) => {
    if (!item || !Number.isInteger(item.productId) || item.productId < 1 || !Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 20 || !Object.hasOwn(sizes, item.size)) throw new ValidationError('Producto, cantidad o extras no válidos.');
    const extras: unknown = item.toppings === undefined ? (item.topping === 'Sin topping' ? [] : [item.topping]) : item.toppings;
    if (!Array.isArray(extras) || extras.length > 9 || extras.some(name => typeof name !== 'string' || name === 'Sin topping' || !Object.hasOwn(toppings, name)) || new Set(extras).size !== extras.length) throw new ValidationError('Toppings no validos.');
    const selected = (extras as string[]).slice().sort();
    return { productId: item.productId as number, quantity: item.quantity as number, size: item.size as string, topping: selected.length ? selected.join(', ') : 'Sin topping', toppings: selected };
  });
  return { customer: body.customer.trim() as string, note: (body.note ?? '').trim() as string, expectedTotal: body.expectedTotal as number, items };
}
export function priceOrder(items: ReturnType<typeof validateOrder>['items'], products: Array<{ id: number; name: string; price: number | string }>) {
  return items.map(item => {
    const product = products.find(p => p.id === item.productId);
    if (!product) throw new ValidationError('Uno de los productos ya no está disponible.');
    const base = Math.round(Number(product.price) * 100);
    if (!Number.isSafeInteger(base) || base < 0) throw new Error('Precio inválido en el catálogo.');
    return { ...item, name: product.name, unitPrice: base + sizes[item.size]! + item.toppings.reduce((sum, name) => sum + toppings[name]!, 0) };
  });
}


