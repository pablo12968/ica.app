# Ice Cream App: cuentas y pedidos reales

El código 1.1.0 incorpora registro con nombre, correo y contraseña, inicio y cierre
de sesión, pedidos por cuenta e historial en PostgreSQL. No indica una tienda de
recogida ni procesa pagos. **La APK anterior sigue siendo demo.** Para generar la
nueva APK conectada hay que publicar el servidor y configurar su URL HTTPS.
No se ha contratado ni publicado alojamiento.

## Consultar tus datos

La cuenta del propietario tiene **Perfil → Administración**, con listas de usuarios
(nombre, correo, registro y último acceso), pedidos (productos, cantidades, extras,
total, notas y referencia) y actividad. Se actualizan manualmente, 50 por página.
El total de pedidos no equivale a dinero cobrado.

Se registran cuentas, inicios y cierres de sesión y pedidos en la misma transacción
que la operación. Carrito y favoritos generan eventos informativos que pueden
perderse si falla la conexión. No se registra cada toque, búsqueda o pantalla.

Tablas: `ica_users`, `ica_orders`, `ica_activity`, `ica_sessions`. Las contraseñas
se guardan mediante hash con sal; los tokens también se guardan como hash en el
servidor. Las cuentas normales no pueden consultar datos de otras personas.

## Publicar en internet (propuesta: Render)

1. Crea una cuenta en Render y un repositorio privado para el código de `ica.app`.
2. Sube el código sin `.env`, claves `.jks`, `key.properties` ni herramientas o
   copias privadas de compilación. Estos archivos están excluidos por `.gitignore`.
3. En Render crea un **Blueprint**, conecta el repositorio y usa `render.yaml`.
4. Revisa el importe antes de aceptar. Se proponen los planes de pago `starter`
   y PostgreSQL `basic-256mb`. Aquí no se ha realizado ningún cobro. No uses una
   base temporal para guardar datos reales.
5. El despliegue compila, ejecuta la migración e inicia el servicio. `DATABASE_URL`
   conecta la base dentro del proveedor; su acceso externo está deshabilitado.
6. Copia la URL HTTPS pública de `ice-cream-api`. Abre `/health`: debe responder
   `{"status":"ok"}`.
7. Configura copias de seguridad y comprueba una restauración antes de depender
   de esos datos. Conserva por separado las claves de firma Android.

La base alojada vacía empieza con un catálogo de ejemplo. Los productos y precios
locales no se trasladan automáticamente: carga el catálogo definitivo y revisa
precios y extras antes de distribuir.

Fuentes: https://render.com/docs/deploy-node-express-app y
https://render.com/docs/blueprint-spec.

También puedes usar otro proveedor Node.js 22+ y PostgreSQL. Incluimos
`backend/Dockerfile`; ejecuta `node dist/migrate.js` antes de iniciar la imagen.
Configura `DATABASE_URL` como secreto. Si el proveedor exige TLS, utiliza su
configuración sin desactivar la validación de certificados.

## Generar la APK conectada

Desde `ica.app`, sustituye la URL de ejemplo:

```powershell
powershell -File scripts/build-android.ps1 -ApiUrl https://TU-API.onrender.com
```

El script ejecuta pruebas y análisis y genera `entrega/Ice-Cream-App.apk`, versión
**1.1.0+2**, con la firma original. Instálala sobre la anterior sin desinstalar.
La compilación exige HTTPS; la app no pasa a simulación cuando falla la conexión.

En este equipo, `frontend/android/local.properties` apunta al SDK de
`D:/IceCreamApp-tools/android-sdk`. Esa unidad no estaba disponible durante esta
preparación. Reconéctala o configura un SDK válido antes de compilar. No se ha
reemplazado la APK anterior por una compilación sin servidor.

## Habilitar tu cuenta administradora

1. Regístrate en la app conectada.
2. En la consola privada del servicio ejecuta:

```text
node dist/admin.js tu-correo@ejemplo.com
```

3. Cierra sesión y vuelve a entrar. Aparecerá **Perfil → Administración**.

El registro público nunca permite elegir el rol administrador. No compartas las
credenciales del servidor o de la base con los clientes.

## Pruebas locales

Desde `backend`: `npm ci`, `npm run db:setup`, `npm start`.
La migración no borra el catálogo ni los pedidos anteriores. Los pedidos sin
cuenta solo aparecen para administración. Los simulados no se convierten en reales.

Desde `frontend`, para el emulador Android:

```text
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

HTTP es solo para desarrollo. En un teléfono físico de la misma red usa la IP
privada del computador. Para distribución utiliza siempre HTTPS.

Pruebas del servidor con PostgreSQL en un esquema temporal aislado:

```powershell
cd backend
$env:TEST_DATABASE='1'
npm test
```

Pruebas Flutter: `flutter test` y `flutter analyze` desde `frontend`.
Antes de compartir, prueba dos cuentas en teléfonos diferentes, sus historiales,
un pedido visible en Administración, cierre de sesión y pérdida de conexión.

## Alcance actual

- Cuentas y pedidos persisten aunque se cierre o reinstale la app.
- La sesión se mantiene en memoria: al cerrar completamente la app hay que volver
  a iniciar sesión. No se guardan contraseñas ni tokens en preferencias locales.
- Favoritos locales separados por cuenta; carrito temporal.
- Sesiones con vencimiento de siete días y revocación al cerrar sesión.
- Sin recuperación ni verificación de correo, pagos, notificaciones, seguimiento
  de entrega o asignación de tienda. El correo identifica la cuenta, pero no se
  verifica todavía que pertenezca a quien se registra.
- El límite de solicitudes es por instancia. La propuesta usa una sola instancia;
  si se escala, debe sustituirse por uno compartido.
- Completa el contacto y la política de privacidad de tu negocio antes de invitar
  clientes públicos. El registro explica qué datos se guardan.
