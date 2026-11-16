# CONDENA — Repertorios v0.1

Implementación experimental en `fighter.gd` y `combat_scene.gd`.

- Tres ranuras: golpe rápido, golpe fuerte y agarre.
- Dos movimientos disponibles por ranura, con costes, alcances y duraciones diferenciados.
- Botón de alternancia entre dos combinaciones predefinidas, solo para probar el prototipo.
- Las técnicas comparten el sistema de resistencia, bloqueo, ruptura de guardia y esquiva.

## Limitaciones

- Aún no existen animaciones propias, hitboxes, aprendizaje/desbloqueo ni persistencia del repertorio.
- Cambiar técnicas durante el combate es una facilidad de depuración; para PvP ranked deberá bloquearse al comenzar la pelea.
- La patada baja todavía no aplica penalización de movilidad; el derribo no tiene estado de suelo. Son variantes de parámetros, no mecánicas completas.
- No se ha ejecutado Godot ni compilado Android para verificar esta versión.

## Próxima implementación

1. Separar la selección de técnicas en una pantalla previa al combate.
2. Crear efectos diferenciados por técnica (patada baja, codazo, derribo) y contrajuego verificable.
3. Registrar métricas de victoria, uso y counters para balance.
4. Probar Godot headless y APK en dispositivo antes de afirmar jugabilidad.
