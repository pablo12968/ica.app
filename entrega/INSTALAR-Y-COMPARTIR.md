# Instalar y compartir Ice Cream App

Esta versión es una prueba gratuita para Android: funciona sin servidor. Los pedidos son simulados, quedan en cada teléfono y no llegan a una heladería. No se realizan cobros. El APK no funciona en iPhone.

El APK incluido ya está generado y su firma se verificó. Requiere Android 7.0 o posterior y ocupa aproximadamente 65 MB. Para instalar esta entrega puedes empezar directamente en el paso 2. Falta comprobarlo en un teléfono físico.

## 1. Generar el APK

Desde la carpeta del proyecto, abre PowerShell y ejecuta:

```powershell
powershell -File scripts/build-android.ps1
```

Espera el mensaje `APK para compartir`. El archivo estará en `entrega/Ice-Cream-App.apk`. Si la compilación muestra un error, todavía no hay una nueva versión lista para compartir. El script comprueba las pruebas, analiza el código y genera una aplicación firmada.

## 2. Instalarlo en tu Android

1. Copia `Ice-Cream-App.apk` al teléfono por cable USB, o sube ese archivo a tu Drive y descárgalo desde el teléfono.
2. En el teléfono, abre **Archivos → Descargas** y toca el APK.
3. Si Android pide autorización, abre **Configuración** desde ese aviso y activa **Permitir desde esta fuente** para la aplicación que abrió el archivo. Los nombres pueden variar según el teléfono.
4. Regresa al instalador, pulsa **Instalar** y después **Abrir**.
5. Una vez instalado, puedes quitar el permiso de instalación a esa fuente. No es necesario desactivar Play Protect.

Referencia: [Ayuda oficial de Google para descargar aplicaciones de otras fuentes](https://support.google.com/pixelphone/answer/7391672?hl=es-419). Si el dispositivo indica que el desarrollador no está verificado, consulta el [procedimiento oficial de Android](https://support.google.com/android/answer/17588095?hl=es-AR); puede variar por dispositivo y región.

## 3. Comprobar la app antes de compartirla

1. Abre un sabor, elige tamaño y cantidad y toca **Personalizar toppings**.
2. Toca **Elegir toppings**, selecciona varios y prueba los filtros y la búsqueda.
3. Abre **Ver resumen**, elimina un topping y comprueba el cambio de precio.
4. Pulsa **Agregar al carrito** y revisa las cantidades y el total.
5. Continúa, escribe tu nombre y pulsa **Simular pedido**. Comprueba el resultado en **Mis pedidos**.
6. Prueba los sonidos; puedes desactivarlos en **Perfil**. Cierra y vuelve a abrir la app para comprobar favoritos e historial. El carrito solo se conserva durante la sesión.
7. Prueba también con el teléfono sin internet.

## 4. Compartirlo

1. En tu almacenamiento, sube únicamente `Ice-Cream-App.apk`.
2. Crea un enlace que permita descargarlo a las personas elegidas y pruébalo antes de enviarlo.
3. Envía el enlace junto con los pasos de instalación de arriba. También puedes enviar el APK como documento si el servicio de mensajería permite ese tipo de archivo.
4. Aclara que es una versión de prueba para Android, con pedidos simulados y sin cobros.

Texto sugerido: «Te comparto Ice Cream App para que la pruebes. Descarga el APK en Android, ábrelo y sigue el aviso de instalación. Puedes elegir helados, toppings y hacer pedidos de prueba. No se cobra ni se envía un pedido real».

## 5. Compartir futuras actualizaciones

Conserva en privado `frontend/android/icecream-release.jks` y `frontend/android/key.properties`. No compartas esos archivos ni la carpeta completa del proyecto. Incrementa la versión en `frontend/pubspec.yaml`, genera otro APK con la misma firma y comparte el nuevo archivo. Para mantener el historial, instala la actualización sobre la aplicación existente, sin desinstalarla.

Si Android indica que la app no se instaló, revisa que la descarga esté completa, haya espacio disponible y la versión anterior use la misma firma. No desinstales la anterior sin antes tener presente que se borrará su historial local.
