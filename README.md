# Ice Cream App

## Actualización 1.1.0: cuentas y pedidos

El código actual incluye registro, inicio/cierre de sesión, pedidos por usuario
en PostgreSQL y **Perfil → Administración** para usuarios, pedidos y actividad.
No asigna tienda de recogida ni procesa pagos. La aplicación ya no activa demo
automáticamente cuando falta `API_URL`; demo solo se habilita expresamente para
pruebas con `DEMO_MODE=true`.

**La APK de `entrega` corresponde todavía a la versión demo anterior.** Falta
publicar la API HTTPS y disponer del SDK Android para generar la APK conectada.
La guía actual de configuración, administración y límites está en
[ACTIVAR-CUENTAS-Y-PEDIDOS.md](entrega/ACTIVAR-CUENTAS-Y-PEDIDOS.md).
Se incluye `render.yaml` para preparar API y PostgreSQL alojados. No se ha
publicado ningún servicio ni contratado alojamiento.

Compilación nueva: `powershell -File scripts/build-android.ps1 -ApiUrl https://TU-API`.
Las notas de entrega demo que siguen describen la versión anterior.

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

### Vista previa de la interfaz

La interfaz sigue la referencia rosa/violeta: imágenes locales de los sabores,
ficha de producto con tamaños, topping y cantidad, carrito editable, búsqueda,
favoritos, historial y perfil. En **Perfil → Sonidos de la app** se puede activar
o silenciar la respuesta sonora; la preferencia se conserva. Los sonidos son
breves y no hay música ni reproducción automática al abrir la app.

Las imágenes ilustrativas se generaron con ImageGen y están en
`frontend/assets/images/`. Los prompts y las fuentes están documentados en
`frontend/assets/README.md`. La tipografía y el audio también se incluyen en la app.

Para regenerar capturas de revisión: desde `frontend`, ejecuta
`flutter test test/visual_preview.dart`. Se guardan en `entrega/preview/`.

Ejecuta `powershell -File scripts/preview.ps1` desde la raíz y abre
`http://127.0.0.1:8080` en el navegador del mismo computador. Mantén el proceso
abierto; tras editar el diseño, pulsa `R` en su terminal y recarga el navegador
si hace falta. Es la app Flutter en modo demo, con catálogo y carrito interactivos.
Los datos de esta vista previa se guardan en el navegador, separados del teléfono.

### Versión para compartir sin servidor

La entrega actual está orientada a probar la aplicación sin pagar alojamiento.
Catálogo, favoritos, personalización, carrito e historial funcionan en el dispositivo;
los pedidos son simulados y no se envían a la heladería. No hay cobros.

Para generar y copiar el APK firmado a `entrega/Ice-Cream-App.apk`:

```powershell
powershell -File scripts/build-android.ps1
```

El script ejecuta pruebas y análisis antes de compilar. Las instrucciones para
instalar y compartir están en `entrega/LEEME.txt`. El identificador Android es
`com.icecreamapp.mobile`. La firma de release usa `frontend/android/key.properties`
y `frontend/android/icecream-release.jks`, excluidos de Git. Conserva una copia
privada de ambos para poder publicar actualizaciones; no los distribuyas con el APK.
El SDK instalado en este equipo está en `D:/IceCreamApp-tools/android-sdk`, fuera
del repositorio, para evitar agotar el disco C:. Su ruta está en el archivo local
`frontend/android/local.properties`.

En este equipo, el script utiliza una copia de compilación en
`D:/IceCreamApp-tools/release-build` y la caché de Gradle en D: para no llenar C:.
La copia de compilación incluye la firma privada y no debe compartirse.
El código que se edita sigue siendo el de este repositorio.

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

Archivo de depuración resultante: `frontend/build/app/outputs/flutter-apk/app-debug.apk`. Para compartir la versión firmada usa `scripts/build-android.ps1` y el APK de la carpeta `entrega`.

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
- Seis pruebas del servidor aprobadas: cálculo, validaciones, productos no disponibles, manipulación de precios y rutas HTTP.
- Migración aplicada a la base configurada; catálogo real consultado correctamente.
- Ocho pruebas Flutter de interfaz, estado y sonidos: pedido completo en pantalla de 390 × 844, búsqueda, favoritos, silencio persistente y vaciado del carrito. Capturas adicionales de revisión visual en `entrega/preview/`.
- Corregidos desbordamientos de las tarjetas y el carrito en pantalla móvil y un aviso que tapaba la confirmación del pedido.
- Pendiente: prueba física en Android/iPhone. Las pruebas automatizadas no sustituyen la comprobación en un teléfono real.

La firma Android de release utiliza una clave propia y ya no utiliza la clave de depuración. No se ha publicado la app en tiendas ni conectado una pasarela de pagos.

Referencias oficiales: https://docs.flutter.dev/deployment/android y https://docs.flutter.dev/deployment/ios.

En esta sesión, con tu confirmación, los ocho precios originales de 2,50 / 3,00 se actualizaron una sola vez a 2.500 / 3.000 COP. La migración normal no vuelve a multiplicarlos. El ZIP contiene el código; tus datos y credenciales permanecen en la instalación original.

## Toppings y distribución Android

Flujo de personalización con nueve toppings, fotos locales, filtros, búsqueda, selección múltiple y resumen editable. Los extras se cobran por unidad y se conservan en el historial simulado. El servidor valida y recalcula los mismos precios.

APK de entrega generado en `entrega/Ice-Cream-App.apk` (68.322.318 bytes), firma v2 verificada, Android mínimo 7.0/API 24. Incluye los recursos de toppings y sonidos sin conexión. Ocho pruebas Flutter y seis del servidor aprobadas; análisis Flutter sin avisos. Pendiente únicamente la prueba en un teléfono físico.

Guía completa para instalar y compartir: [entrega/INSTALAR-Y-COMPARTIR.md](entrega/INSTALAR-Y-COMPARTIR.md). Recursos y prompts de las fotos: [frontend/assets/TOPPINGS-PROMPTS.md](frontend/assets/TOPPINGS-PROMPTS.md).
