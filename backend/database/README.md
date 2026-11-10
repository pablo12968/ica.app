# Base de datos del proyecto

El repositorio incluye la estructura en `../schema.sql` y una copia del catálogo
local en `catalog.json`, con nombres, descripciones, categorías, precios COP y
disponibilidad. Se conservan los ocho productos y sus identificadores, incluso
los nombres repetidos que existen en la base original.

No incluye usuarios, hashes de contraseñas, sesiones, pedidos personales, eventos
de usuarios ni credenciales. Esos datos siguen en PostgreSQL local. GitHub almacena
los archivos para reproducir la base; no ejecuta PostgreSQL ni recibe cambios
automáticamente cuando editas precios en pgAdmin.

## Instalar en otro equipo

1. Instala PostgreSQL y crea una base vacía llamada `ica_db` desde pgAdmin.
2. Desde `backend`, copia `.env.example` a `.env` y configura el usuario y la
   contraseña de ese equipo. Usa `DATABASE_URL` en lugar de DB_* si corresponde.
3. Ejecuta:

```powershell
npm ci
npm run db:setup
npm run db:catalog:import -- --apply
npm start
```

`db:setup` crea las tablas sin borrar datos. La importación explícita agrega los
productos del archivo y actualiza los nombres y precios de los IDs que ya
existen. No elimina productos adicionales, usuarios ni pedidos. En una base con
datos propios revisa primero el catálogo: importar reemplaza sus precios para
esos IDs. Los pedidos históricos mantienen el detalle original.

## Abrir Chrome conectado

En otra terminal, desde `frontend`:

```powershell
flutter run -d chrome --web-port=49327 --dart-define=API_URL=http://localhost:3000 --dart-define=DEMO_MODE=false
```

También puedes elegir **Ice Cream App - Chrome conectado** en Ejecutar y depurar
de VS Code. `.env` debe contener `CORS_ORIGIN=http://localhost:49327`. Reinicia el
servidor después de cambiar esa variable. `10.0.2.2` se reserva para el emulador
Android, no para Chrome.

Registra una cuenta desde la aplicación. Los datos aparecerán en pgAdmin en
`ica_db → Schemas → public → Tables`. Para habilitar al propietario, ejecuta en
el servidor `npm run admin:grant -- tu-correo@ejemplo.com` con una cuenta existente.

## Actualizar los precios que se comparten en Git

Después de editar productos en pgAdmin, desde `backend`:

```powershell
npm run db:catalog:export
```

Revisa el cambio de `database/catalog.json` antes de hacer commit y push. Este
comando solo lee el catálogo; no exporta las demás tablas. La importación no
forma parte del inicio normal del servidor para no sobrescribir precios locales
en cada ejecución.
