import 'package:flutter/material.dart';

import 'store.dart';
import 'models.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.store});
  final ShopStore store;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool register = false, busy = false, visible = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.authenticate(
        email.text,
        password.text,
        name: register ? name.text : null,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is OrderFailure
              ? e.message
              : 'No pudimos conectar. Revisa tu conexión e intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ice Cream App')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Icon(
                Icons.icecream_rounded,
                size: 70,
                color: Color(0xff7844cf),
              ),
              const SizedBox(height: 20),
              Text(
                register ? 'Crea tu cuenta' : 'Qué bueno verte',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu cuenta, tus helados y tus pedidos en un solo lugar.',
              ),
              const SizedBox(height: 24),
              if (!widget.store.configured)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Estamos preparando la conexión del servicio. El registro estará disponible cuando se configure el servidor.',
                  ),
                ),
              if (register) ...[
                TextFormField(
                  controller: name,
                  enabled: !busy,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v?.trim().length ?? 0) < 2 ? 'Escribe tu nombre.' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                maxLength: 254,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator: (v) =>
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Escribe un correo válido.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: password,
                enabled: !busy,
                obscureText: !visible,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 128,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo 10 caracteres',
                  suffixIcon: IconButton(
                    tooltip: visible
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: () => setState(() => visible = !visible),
                    icon: Icon(
                      visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (v) => (v?.length ?? 0) < 10
                    ? 'Usa al menos 10 caracteres.'
                    : null,
              ),
              if (register) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmation,
                  enabled: !busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Repite tu contraseña',
                  ),
                  validator: (v) => v != password.text
                      ? 'Las contraseñas no coinciden.'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Guardamos tu nombre, correo, pedidos y actividad de la cuenta para gestionar el servicio. La administración puede consultar estos datos; tu contraseña no se muestra.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy || !widget.store.configured ? null : submit,
                child: Text(
                  busy
                      ? 'Conectando…'
                      : register
                      ? 'Crear cuenta'
                      : 'Iniciar sesión',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        register = !register;
                        error = null;
                        form.currentState?.reset();
                      }),
                child: Text(
                  register
                      ? 'Ya tengo cuenta · Iniciar sesión'
                      : 'Crear una cuenta',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.store});
  final ShopStore store;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String section = 'orders';
  int page = 0;
  late Future<Map<String, dynamic>> data;
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<Map<String, dynamic>> load() async =>
      await widget.store.request('admin/$section?page=$page')
          as Map<String, dynamic>;
  void refresh() => setState(() => data = load());
  String date(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? ''
        : '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String event(dynamic value) =>
      const {
        'account_registered': 'Cuenta creada',
        'session_started': 'Inicio de sesión',
        'session_ended': 'Cierre de sesión',
        'order_created': 'Pedido recibido',
        'favorite_added': 'Favorito agregado',
        'favorite_removed': 'Favorito retirado',
        'cart_updated': 'Carrito actualizado',
      }[value] ??
      '$value';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administración'),
      actions: [
        IconButton(
          onPressed: refresh,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: section,
            items: const [
              DropdownMenuItem(
                value: 'orders',
                child: Text('Todos los pedidos'),
              ),
              DropdownMenuItem(
                value: 'users',
                child: Text('Usuarios registrados'),
              ),
              DropdownMenuItem(value: 'activity', child: Text('Actividad')),
            ],
            onChanged: (v) {
              section = v!;
              page = 0;
              refresh();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          snapshot.error is OrderFailure
                              ? (snapshot.error as OrderFailure).message
                              : 'No se pudieron cargar los datos.',
                        ),
                        TextButton(
                          onPressed: refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final rows = snapshot.data!['rows'] as List;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay registros en esta página.'),
                    ),
                  for (final row in rows)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (section == 'users') ...[
                              Text(
                                '${row['name']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText('${row['email']}'),
                              Text('Rol: ${row['role']}'),
                              Text('Registro: ${date(row['created_at'])}'),
                              Text(
                                'Último acceso: ${date(row['last_login_at'])}',
                              ),
                            ] else if (section == 'orders') ...[
                              Text(
                                '${row['payload']['customer']} · ${money((row['payload']['total'] as num).round())}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                '${row['email'] ?? 'Pedido anterior sin cuenta'}',
                              ),
                              Text(
                                '${row['payload']['status']} · ${date(row['created_at'])}',
                              ),
                              for (final item
                                  in row['payload']['items'] as List)
                                Text(
                                  '${item['quantity']} × ${item['name']} · ${item['size']} · ${item['topping']}',
                                ),
                              if ('${row['payload']['note'] ?? ''}'.isNotEmpty)
                                Text('Nota: ${row['payload']['note']}'),
                              SelectableText('Referencia: ${row['id']}'),
                            ] else ...[
                              Text(
                                event(row['event']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText('${row['email'] ?? ''}'),
                              Text(date(row['created_at'])),
                              if (row['details']?['orderId'] != null)
                                SelectableText(
                                  'Pedido: ${row['details']['orderId']}',
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: page == 0
                            ? null
                            : () {
                                page--;
                                refresh();
                              },
                        child: const Text('Anterior'),
                      ),
                      Text('Página ${page + 1}'),
                      TextButton(
                        onPressed: snapshot.data!['hasMore'] == true
                            ? () {
                                page++;
                                refresh();
                              }
                            : null,
                        child: const Text('Siguiente'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
