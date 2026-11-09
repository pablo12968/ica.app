# Reproducción de métricas de ICA

Desde la raíz del repositorio, con Node.js, Dart 3.13.2 y las dependencias de `backend` instaladas:

```powershell
$repo = (Get-Location).Path
node metricas/typescript.cjs "$repo" > medicion-typescript.json
Push-Location metricas/dart
dart pub get
dart run medir.dart "$repo" > "$repo/medicion-dart.json"
Pop-Location
```

La salida registra la herramienta, la ruta, la huella SHA-256, las líneas efectivas, las importaciones internas y las unidades con línea inicial, LOC y V(G). Las huellas identifican el contenido exacto por archivo. Los archivos `base-*.json` corresponden al árbol local revisado. `despues-typescript.json` corresponde a esa misma copia con la refactorización de pedidos aplicada. Los resultados Dart permanecen válidos para ambas mediciones.

| Indicador | Cálculo e interpretación |
|---|---|
| V(G) | 1 + decisiones sintácticas dentro de la unidad. Se cuentan condicionales, bucles, casos, capturas, ternarios y operadores binarios `&&`, `\|\|` y `??`. Dart incluye condicionales y bucles en colecciones. Las decisiones de funciones anidadas se asignan a su propia unidad. Riesgo bajo 1–10, moderado 11–20, alto 21–50 y muy alto por encima de 50. |
| LOC efectivas | Líneas con al menos un token de código, incluida la puntuación sintáctica. Por archivo cada línea se cuenta una vez. El intervalo de una unidad puede incluir las líneas de funciones anidadas y compartir líneas con otras unidades. Más de 50 LOC por unidad ameritan revisión según la guía. |
| Dependencias internas directas | Número de archivos distintos dentro del mismo árbol medido a los que apuntan las importaciones o reexportaciones estáticas reconocidas. Cada destino cuenta una vez. Se excluyen paquetes externos, llamadas HTTP y relaciones transitivas. Para este proyecto se marca revisión por encima de 3. Un módulo de composición puede superar ese valor con una justificación arquitectónica. |

Los analizadores usan la API de sintaxis de TypeScript y `package:analyzer` de Dart. El recuento se limita a `backend/src/**/*.ts` sin declaraciones `.d.ts` y `frontend/lib/**/*.dart`. Los archivos de plataforma, pruebas, SQL, recursos, dependencias y código generado fuera de esos árboles quedan fuera del recuento. Las decisiones a nivel de módulo carecen de una unidad ejecutable a la que atribuir V(G). El conteo es una aproximación sintáctica de McCabe.

## Repetir la comparación

1. Mide la línea base y guarda sus archivos JSON.
2. En una rama o copia limpia, ejecuta `git apply --check docs/refactorizacion/validacion-pedidos.patch` y, si la verificación pasa, `git apply docs/refactorizacion/validacion-pedidos.patch`.
3. Repite las mediciones y verifica las ocho pruebas del servidor con PostgreSQL habilitado.
4. Compara `backend/src/order.ts` por nombre de unidad. El cambio mueve decisiones a funciones con un propósito específico. El máximo local disminuye aunque el archivo suma seis líneas efectivas.
