# Verificación de cuentas y pedidos — 31 de octubre de 2026

- 14 pruebas Flutter aprobadas: registro, validación de contraseña, historial por
  API, reintentos, limpieza al cerrar sesión, rechazo de respuestas tardías,
  ausencia de simulación automática y pruebas existentes de compras y sonidos.
- 8 pruebas del servidor aprobadas, incluyendo integración contra PostgreSQL en
  un esquema temporal aislado y eliminado después de la prueba.
- Integración comprobada: correo único normalizado, hash de contraseña, rechazo
  de contraseña incorrecta, rol de cliente forzado en registro, protección de
  administración, separación entre cuentas, historial, precio validado por el
  servidor, idempotencia, auditoría, cierre y vencimiento de sesión.
- Migración aplicada a PostgreSQL local. Tablas presentes: `ica_users`,
  `ica_sessions`, `ica_orders`, `ica_activity`. No se crearon usuarios de prueba
  en las tablas del propietario.
- TypeScript compila; sintaxis del script de compilación PowerShell comprobada.

Pendiente: despliegue del servidor HTTPS, alta de la cuenta del propietario y
habilitación de su rol, disponibilidad del SDK Android, compilación de la APK
conectada y prueba en teléfono físico. La APK anterior no se ha reemplazado.
