# CONDENA — Prototipo 1v1 local v0.5

## Objetivo
Probar el sistema de contrajuego con dos personas reales en el mismo computador antes de asumir complejidad de servidores, matchmaking o PvP en línea.

## Modo duelo
- Antes de iniciar, alternar **RIVAL: IA (CAMBIAR)** a **RIVAL: JUGADOR 2**.
- La IA queda desactivada en ese combate; ambos personajes pueden controlar ataques, defensa y movimiento simultáneamente.
- Jugador 1: A/D movimiento, J/K/L ataques, F parada, E amague, ESPACIO esquiva, SHIFT bloqueo.
- Jugador 2: flechas movimiento, 1/2/3 ataques, 4 esquiva, 5 parada, 6 amague, 0 bloqueo.
- Modo de retransmisión local: tecla V oculta controles táctiles, manteniendo barras, cronómetro y eventos.

## Contrajuego existente
- Bloqueo reduce daño, pero pierde ante agarres.
- Parada perfecta de ventana breve supera golpes, pero pierde ante agarres y castiga intentos fallidos.
- Esquiva perfecta crea oportunidad de contraataque; esquivar mal deja recuperación.
- Amague provoca reacciones y también tiene coste y recuperación.
- Golpes confirmados pueden encadenarse en combos con daño escalado.

## Verificación
- Se agregó aserción automática para que el modo local desactive la IA.
- Tests en tests/combat_smoke.gd, ejecutados por GitHub Actions cuando haya runners disponibles.
- **Sin validación confirmada de Godot o Android todavía.** No declarar APK disponible.
- El modo local es para un teclado en computador: **no existe multijugador por red ni dos teléfonos**.

## Próximo paso
Revisar CI y resolver errores; animaciones de golpes por estados y hitboxes precisas; construir APK de pruebas; observar partidas humanas y ajustar equilibrio.

## Costos
Todo implementado sin gastar créditos de generación ni ejecutar compras.

## Continuación — feedback de combate y registro local
- Animación procedural con fases de preparación, extensión y recuperación del golpe.
- Poses específicas para patada baja y derribo; desplazamiento de piernas durante caminata.
- Reacción de retroceso visual cuando un personaje recibe daño.
- Impulso breve de cámara al conectar, más fuerte en cross y derribo.
- Al terminar, guarda `user://condena_last_match.json` con ganador, duración, modo, estadísticas y eventos.
- El archivo es **local**: no se transmite a servidores ni es todavía una repetición visual.
- Smoke test ampliado para patada baja, derribo, historial y persistencia JSON.
- **Estado:** cambios subidos al repositorio, sin ejecución Godot verificada en este entorno.
