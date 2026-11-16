# CONDENA — Integración V0.2

Esta rama conserva el prototipo `src/combat/combat_scene.tscn` de V0.1 y no reemplaza la escena principal.

## Integrado
- CharacterAnimator con estados de acción y recuperación tras animación no cíclica.
- ProgressionManager: año 1 a 10 y desbloqueo ranked en año 5.
- SaveSystemV2: JSON versionado y escritura temporal.
- Adaptador de controles táctiles para CondenaFighter.
- Especificación de los tres arquetipos de IA.

## Pendiente
- Crear SpriteFrames reales y animaciones no cíclicas de acciones.
- Integrar el gestor de animación con los combatientes existentes.
- Implementar agarre y un sistema de hitbox/hurtbox con ventanas de impacto.
- Convertir los botones prototipo en joystick multitáctil.
- Implementar IAs completas de El Flaco y Preso Grande.
- Probar importación Godot y exportación Android.
- Integrar el guion íntegro y las viñetas oficiales.

No afirmar que la APK está lista: no hay validación de motor ni dispositivo.
