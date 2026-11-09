# Evidencia de la revisión de ICA

La medición se realizó sobre el árbol local basado en el commit `6d7882d`, que contenía cambios adicionales. Las huellas SHA-256 identifican los 19 archivos analizados. La comparación se hizo en una copia con el parche de validación aplicado.

| Archivo | Contenido |
|---|---|
| `base-typescript.json` | Línea base de 11 archivos TypeScript y 40 unidades ejecutables. |
| `base-dart.json` | Línea base de 8 archivos Dart y 236 unidades ejecutables. |
| `despues-typescript.json` | Medición TypeScript tras la extracción de las validaciones. La medición Dart sigue siendo la de la línea base. |
| `pruebas-servidor-antes.txt` y `pruebas-servidor-despues.txt` | Salidas del ejecutor de Node con ocho pruebas aprobadas por ejecución. |

Las dos ejecuciones usaron Node.js 24.20.0 y PostgreSQL 17.11 con datos ficticios, en una instancia local aislada. Desde `backend`, primero se compiló con `npm run build`. Después, con `TEST_DATABASE=1` y una conexión a PostgreSQL de prueba, se ejecutó:

```text
node --test --test-isolation=none --test-reporter=spec test/order.test.cjs test/accounts.test.cjs
```

La suite Flutter no llegó a ejecutarse en este entorno. Los casos citados en la matriz de requisitos corresponden a pruebas existentes en `frontend/test`.
