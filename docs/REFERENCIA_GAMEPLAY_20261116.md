# CONDENA — Referencia de gameplay recibida 16-11-2026

Fuente: video de gameplay proporcionado por el usuario (10 segundos). Es referencia de calidad mínima, NO una demostración del estado actual del proyecto Godot.

## Elementos observables
- Vista lateral 2D, personajes con anatomía manga seinen en blanco y negro.
- Patio/interior de módulo carcelario con rejas, público y fondo detallado.
- HUD superior: retratos, nombres, nivel, vida, resistencia, ronda y cronómetro.
- Joystick inferior izquierdo; botones táctiles inferiores derechos para bloqueo, esquiva, agarre, golpe rápido y fuerte; medidor especial.
- Reacciones e impactos estilizados.

## Criterios de aceptación para superar la referencia
1. Ataques solo conectan cuando hitbox activa intersecta hurtbox del adversario; no usar solo distancia entre centros.
2. Hitboxes activas únicamente en los fotogramas de contacto, vinculadas a animación y orientación.
3. Colisiones de cuerpos que impiden atravesarse; empuje y separación estable.
4. Estados de locomoción, ataque, bloqueo, esquiva, impacto, caída y recuperación con transiciones sin saltos.
5. Feedback: hitstop corto, retroceso y efectos visuales solo cuando hay contacto confirmado.
6. Iconos individuales para técnicas equipadas: jab, patada baja, cross, codazo, clinch y derribo. Los botones muestran técnica, cooldown y coste de resistencia, y se actualizan al cambiar repertorio.
7. Selección de repertorio antes de combatir, bloqueada durante ranked.
8. HUD adaptado a 1280x720 y áreas seguras móviles; no tapar personajes con botones.
9. Verificar en Godot y Android la fluidez y consistencia; medir FPS y latencia táctil.

## Prioridad de implementación
P0: colisión corporal + hitboxes/hurtboxes + sincronía visual.
P1: estados de animación y feedback de contacto.
P2: iconografía y HUD de técnicas configurables.
P3: arte final, fondos y público animado.

No afirmar que estas mejoras ya están implementadas. No reemplazar fotografías reales ni atribuir el video a una compilación del repositorio.
