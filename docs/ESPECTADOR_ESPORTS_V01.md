# CONDENA — Experiencia de espectador y potencial competitivo

Visión del director creativo, 16-11-2026: que mirar un 1v1 sea entretenido por la violencia estilizada, la claridad táctica y la posibilidad de comentar/narrar jugadas. Meta a largo plazo: comunidad, fans, creadores, torneos y comentaristas. No afirmar que estas funciones ya existen.

## Tres capas simultáneas
1. **Impacto emocional:** personajes expresivos, animaciones con peso, sonido de contacto, tensión de resistencia, reacciones y público; sin sacrificar lectura.
2. **Lectura táctica:** anticipaciones, fintas, counters, castigos de recuperación, cambio de repertorio y combos identificables.
3. **Narrativa de la pelea:** remontadas, adaptaciones, estilos y rivalidades legibles incluso sin jugar.

## Información para espectadores
- HUD de retransmisión con vida, resistencia, técnica equipada y tiempo; no ocultar acción.
- Indicadores discretos y temporales: BLOQUEO PERFECTO, ESQUIVA, INTERRUPCIÓN, CASTIGO, CONTRAATAQUE, COMBO xN.
- Historial reciente de acciones para comentaristas, con tiempos y jugadores.
- Repeticiones cortas y cámara lenta en jugadas decisivas (solo modo espectador/replay, nunca altera simulación).
- Modo retransmisión sin botones táctiles, con overlays opcionales y zona limpia para cámara del streamer.
- Estadísticas al cierre: daño por técnica, acierto, bloqueos, fintas exitosas, castigos, combos, recursos gastados.

## Arquitectura de eventos desde el prototipo
Registrar eventos de combate desacoplados de la interfaz: attack_started, attack_whiffed, hit_confirmed, guarded, guard_broken, dodged, counter_hit, combo_extended, knockdown, defeated. Cada evento con atacante, defensor, técnica, tiempo de simulación, posición y resultado. Sin registrar datos personales.
La interfaz de jugador consume solo señales mínimas; replay, observador y estadísticas pueden consumir el mismo flujo más adelante.

## Diseño de espectáculo
- Animación y sonido diferentes por clase de técnica.
- Impacto visual de 80–150 ms según fuerza, sin tapar contrajuego ni marear.
- Movimientos reconocibles incluso con efectos apagados.
- Narradores pueden identificar decisiones por nombre, riesgo y castigo.
- Cámara mantiene ambos luchadores y la distancia táctica en pantalla; no zoom exagerado en ataques comunes.

## Camino realista
P0: juego local sólido, hitboxes y estados de animación.
P1: eventos de combate y HUD legible.
P2: repetición determinista o grabación de estados y modo espectador local.
P3: red 1v1 con sincronización, latencia y anti-trampas.
P4: salas privadas, espectador online, repeticiones, torneos y herramientas de emisión.

## Principios de monetización
La retransmisión y el PvP no venden ventajas. Cosméticos legibles en stream y personalización pueden financiar desarrollo, sin bloquear la experiencia de espectadores.
