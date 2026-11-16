# CONDENA — Combate competitivo (prototipo v0.3)

## Principio
El jugador aprende técnicas durante la campaña y configura su repertorio; ninguna disciplina debe dominar sin contrajuego. El PvP ranked se desbloquea en el año 5 de la historia. Las temporadas podrán ajustar balance sin borrar progreso.

## Triángulo de contrajuego inicial implementado
- Bloqueo reduce daño directo, pero ahora gasta resistencia y acumula presión de guardia.
- Agarre atraviesa bloqueo, lo desactiva y provoca una breve interrupción; alcance menor y coste de resistencia.
- Esquiva concede invulnerabilidad breve a cambio de resistencia, y permite evitar ataques y agarres si está bien sincronizada.
- Ataque fuerte genera más presión de guardia que el rápido, pero tiene mayor coste y recuperación.

## Pendiente antes de afirmar que existe un meta competitivo
1. Validar en Godot la ejecución y la interacción de golpes, bloqueos, agarres y esquivas.
2. Añadir hitboxes/hurtboxes, ventanas de inicio/actividad/recuperación, orientación y animaciones.
3. Prototipar equipamiento de técnicas (loadout) con restricciones y costes claros.
4. Añadir entrenamiento y desbloqueo de técnicas sin ventajas de pago en ranked.
5. Definir pruebas de balance: tasas de victoria por técnica y combinación, diversidad de repertorios, contrajuego y latencia.
6. Diseñar combate en red autoritativo y antitrampas antes de lanzar ranked.

## Pruebas manuales prioritarias
- Bloquear varios rápidos: baja resistencia y vida reducida.
- Bloquear fuertes: la guardia termina rompiéndose.
- Bloquear un agarre a corta distancia: no protege del agarre.
- Esquivar un agarre en la ventana correcta: no recibe daño.
- Atacar fuera de alcance: no hace daño.
- Quedarse sin resistencia: no permite ataques ni esquivas con coste.
- Verificar que las derrotas terminan el combate y no producen ataques posteriores.

Valores y timings son experimentales, no balance definitivo.
