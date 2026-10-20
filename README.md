# Ice Cream App

Aplicación Flutter para Android/iOS y servidor Node.js + PostgreSQL. El proyecto se encuentra en `Documentos\Ice Cream App\ica.app` (Documentos está sincronizado con OneDrive).

## Funciones

- Catálogo, búsqueda, categorías y favoritos.
- Personalización por tamaño y topping, cantidades y carrito.
- Pedido para recoger, nombre y nota opcional.
- Historial de pedidos y favoritos guardados en el dispositivo.
- Demo sin servidor: pedidos simulados y sin cobros.
- Modo conectado: catálogo existente y pedidos guardados en PostgreSQL.
- Validación de precios en el servidor y referencias para evitar duplicados al reintentar durante la misma sesión.

Los pedidos conectados quedan como «Recibido». No se ha implementado seguimiento en tiempo real, panel de empleados, pagos electrónicos ni cuentas de usuario. El carrito se mantiene durante la sesión; el historial y los favoritos se conservan al cerrar la app.

## Abrir en Visual Studio Code

1. Abre `Ice Cream App.code-workspace`.
2. Instala la extensión Flutter recomendada si no la tienes.
3. Selecciona un dispositivo Android conectado por USB o un emulador.
4. En **Ejecutar y depurar**, selecciona **Ice Cream App · Demo** y pulsa **F5**.

La configuración **API local Android** usa `http://10.0.2.2:3000`, la dirección del ordenador desde un emulador Android. **Servidor propio** solicita la URL de tu API.

## Preparar Flutter y probar

El proyecto utiliza Flutter 3.47.2 / Dart 3.13.2, presentes en este equipo. Desde `frontend`:

```text
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

Para Android necesitas el SDK y un dispositivo o emulador. Para generar un instalador de prueba:

```text
flutter build apk --debug
```

Archivo resultante: `frontend/build/app/outputs/flutter-apk/app-debug.apk`. Este archivo NO viene incluido en la entrega: su compilación sigue pendiente.

## Servidor y base de datos

Desde `backend`:

```text
npm install
```

Para una instalación nueva, crea una base PostgreSQL y copia `.env.example` a `.env`, indicando sus datos de conexión. Conserva el `.env` existente en este ordenador. Después:

```text
npm run db:setup
npm test
npm start
```

`db:setup` compila y ejecuta una migración aditiva: crea `ica_orders`, añade categorías y conserva los productos existentes. Solo carga productos de ejemplo si el catálogo está vacío. No sobrescribe precios existentes.

El catálogo original utiliza `base_price`; la API lo expone como `price`. `GET /api/products` devuelve solo productos disponibles. `POST /api/orders` valida artículos y calcula los precios; requiere `Idempotency-Key`. No hay una ruta pública para consultar datos personales de otros pedidos.

Los importes del catálogo se guardan en pesos colombianos. Los cálculos internos y los importes de los pedidos usan centavos enteros para evitar errores con decimales. Los suplementos están definidos en `frontend/lib/models.dart` y `backend/src/order.ts` y deben mantenerse iguales.

## Conectar el móvil

Para un emulador Android, desde `frontend`:

```text
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

Para un Android físico, conecta el teléfono a la misma red y usa la IP local del ordenador:

```text
flutter run --dart-define=API_URL=http://IP_DEL_ORDENADOR:3000
```

El servidor debe estar iniciado y el teléfono debe poder acceder al puerto 3000. `localhost` en un teléfono se refiere al teléfono. Se permite HTTP local únicamente en la configuración Android de depuración. Para distribuir una app conectada utiliza un servidor HTTPS estable y pasa su URL en `API_URL` al compilar. Sin `API_URL`, la app siempre inicia en demo.

## iPhone

El código y el proyecto iOS están incluidos. Para compilar y ejecutar en iPhone se necesita un Mac con Xcode y la configuración de firma de Apple. Usa HTTPS para el servidor. No es posible generar un instalador iOS desde este Windows.

## Estado de la verificación

- Dependencias Flutter resueltas y formato Dart validado.
- Análisis estático de archivos Dart y pruebas: sin errores ni avisos.
- Servidor TypeScript compilado.
- Cinco pruebas del servidor aprobadas: cálculo, validaciones, productos no disponibles, manipulación de precios y rutas HTTP.
- Migración aplicada a la base configurada; catálogo real consultado correctamente.
- Pruebas Flutter de interfaz y estado incluidas, pero no ejecutadas.
- Pendiente: compilación APK y prueba física en Android/iPhone. El entorno automatizado denegó procesos secundarios de Flutter; esto no equivale a una compilación correcta.

La firma Android de release conserva la configuración de desarrollo de la plantilla. Antes de publicar en una tienda, configura un identificador propio y la firma de producción. No se ha publicado la app ni conectado una pasarela de pagos.

Referencias oficiales: https://docs.flutter.dev/deployment/android y https://docs.flutter.dev/deployment/ios.

En esta sesión, con tu confirmación, los ocho precios originales de 2,50 / 3,00 se actualizaron una sola vez a 2.500 / 3.000 COP. La migración normal no vuelve a multiplicarlos. El ZIP contiene el código; tus datos y credenciales permanecen en la instalación original.
