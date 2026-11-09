# Guion de sustentación de Ice Cream App

| Tiempo | Demostración | Qué explicar |
|---|---|---|
| 0:00–0:40 | Presentar el alcance. | El cliente personaliza y registra un pedido para recoger. El administrador consulta la actividad. |
| 0:40–2:00 | Abrir el catálogo, buscar un sabor, guardarlo como favorito, elegir tamaño y toppings y ajustar la cantidad. | Señalar los criterios de aceptación y mostrar cómo cambia el total. |
| 2:00–3:15 | En modo conectado, entrar con un cliente de prueba, confirmar un pedido y abrir su historial. Luego abrir Administración con otra cuenta de prueba. | Mostrar el estado Recibido, la referencia del pedido y su registro en actividad. Si se usa la demo, identificar el estado Simulado y mostrar la evidencia del servidor por separado. |
| 3:15–4:00 | Mostrar el diagrama y los archivos `store.dart`, `order.ts` y las rutas. | Flutter envía la configuración. La API autoriza, recalcula e inserta en PostgreSQL. Una clave de idempotencia evita registrar el mismo intento dos veces. |
| 4:00–5:15 | Mostrar la tabla de resultados y el parche. | Diferenciar V(G), tamaño y dependencias directas. Comparar el máximo local 15 → 9 y las pruebas 8/8 → 8/8. Explicar por qué autenticación sigue como prioridad con V(G)=22. |
| 5:15–5:45 | Mostrar el repositorio y las contribuciones del equipo. | Identificar el commit o etiqueta final y explicar el aporte de cada persona. |

Usar cuentas, catálogo y pedidos de prueba. Verificar la demo y el modo conectado en el equipo de presentación. Preparar una pantalla con los resultados JSON y otra con la prueba de integración.

**Preguntas para ensayar**

- ¿Por qué se valida el total en el servidor? El cliente puede enviar un importe alterado y el catálogo puede cambiar antes de confirmar.
- ¿Por qué más líneas pueden coexistir con menor complejidad? La extracción distribuye las decisiones entre unidades con responsabilidades delimitadas y agrega declaraciones y llamadas.
- ¿Por qué un punto de entrada tiene varias dependencias? `app.ts` y `main.dart` conectan componentes. El conteo es una señal para revisar la responsabilidad de cada archivo.
