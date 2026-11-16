# CONDENA — Filosofía de combate 1v1

Objetivo del director creativo (16-11-2026): el duelo debe sentirse como un encuentro competitivo donde gana quien usa mejor las habilidades, sus combinaciones, posicionamiento y timing. Evitar el intercambio por turnos y el bloqueo universal.

## Principios innegociables
- Acciones simultáneas en tiempo real: ambos pueden iniciar, cancelar, defender y castigar; sin turnos.
- Cada técnica tiene **inicio (startup), ventana activa, recuperación, alcance y coste**. La recuperación es castigable.
- El defensor siempre dispone de decisiones, pero ninguna respuesta es universal.
- Cada habilidad fuerte debe tener contrajuego y ese contrajuego también debe ser castigable.
- Combos basados en lectura, distancia, confirmación de impacto y gestión de recursos; no cadenas infinitas.
- El rival derrotado debe entender por qué perdió y qué podría hacer distinto.

## Relaciones de contrajuego propuestas
| Acción | Puede superar | Es vulnerable a |
|---|---|---|
| Bloqueo | golpes directos previsibles | agarres, presión de guardia, amagues |
| Esquiva | ataques comprometidos | fintas, seguimiento, castigo en recuperación |
| Golpe rápido | inicio de golpes lentos, combos cortos | bloqueo bien medido, rango superior |
| Golpe fuerte | guardia desgastada, castigo tras error | interrupción temprana, esquiva |
| Agarre | bloqueo pasivo | separación, interrupción antes de conectar |
| Patada baja | movilidad y posicionamiento | distancia, esquiva, contraataque |
| Derribo | rival expuesto o bloqueando | interrupción y lectura del intento |
| Amague | reacción defensiva prematura | rival paciente, ataque rápido |

## Ejemplo de secuencia emergente
1. A usa golpe fuerte y B esquiva; B obtiene una ventana de castigo.
2. A anticipa la esquiva y cancela el ataque con una finta; B esquiva en falso.
3. A castiga recuperación de B con jab; B responde con defensa activa y reposicionamiento.
4. B lee la siguiente finta y ataca primero. No hay una respuesta ganadora fija.

## Combos
- Ventanas de enlace acotadas tras contacto confirmado.
- Escalado de daño y empuje por golpe para impedir combos infinitos.
- Recuperación defensiva posible mediante recurso limitado, no con bloqueo infinito.
- Distintos estilos: presión, movilidad, control de distancia y contraataque, sin clases bloqueadas.

## MVP implementable en orden
1. Corregir ejecución de Godot y validar colisiones/hitboxes.
2. Introducir estados explícitos startup/active/recovery, con hit confirm.
3. Finta con coste y vulnerabilidad; castigo de recuperación de esquiva.
4. Contraataque de precisión con ventana corta y feedback visual.
5. Ventanas de combo con escalado de daño y límite de golpes.
6. IA capaz de fintar, defender y castigar errores, sin leer inputs del jugador.
7. Pruebas PvP con latencia y rollback o reconciliación de red antes de prometer ranked.

## Reglas PvP
- Estadísticas de combate normalizadas.
- Ninguna microtransacción modifica daño, frames, alcance, resistencia ni técnicas disponibles.
- El contenido de pago es expresivo/cosmético, no una ventaja.
- Telemetría de balance: tasa de uso, tasa de éxito y counters por técnica; ajustar con partidas reales.

**Estado:** especificación de diseño; NO afirmar que las fintas, ventanas de combo, parries o red online estén implementadas.
