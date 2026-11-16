# CONDENA — Producción de fotogramas

## Referencia aprobada
- Hacker: hombre chileno de 27 años, cabello negro desordenado, delgado, ropa carcelaria sencilla.
- El Chico: ~30 años, pelo corto, constitución atlética, expresión desafiante.
- Escenario: comedor del Módulo B, presos espectadores, rejas, hormigón y luces fluorescentes.
- Blanco y negro, tramas manga seinen, alto detalle y anatomía coherente.
- El gameplay aprobado utiliza interfaz táctil y vista lateral.

## Reglas de producción
1. Crear **fotogramas individuales** a partir de poses maestras consistentes; no recortar personajes diminutos de la lámina conceptual.
2. Un PNG RGBA por fotograma, transparente, 512×512, pies alineados en el mismo punto de apoyo.
3. No alterar rostro, proporciones, vestuario, escala o dirección de iluminación entre fotogramas.
4. Nombres: `assets/characters/hacker/idle/000.png`, `001.png`, etc.
5. Mantener ataques en secuencias no cíclicas; `idle` y `walk` sí pueden ciclar.
6. Usar `assets/animation_manifest.json` como especificación inicial de secuencias.
7. Validar visualmente movimiento, silueta, contacto, desplazamiento y continuidad antes de integrar.
8. Separar escenario en fondo/rejas, mesas/presos y suelo/reflejos para parallax.

## Estado real
La imagen conceptual generada **no** es un spritesheet de producción ni equivale a los fotogramas individuales.
Aún falta generar, revisar, exportar e integrar las secuencias PNG reales.
