# El Pollo · estado de desarrollo para PC

| Etapa publicada | Cambios y archivos principales | Verificación |
|---|---|---|
| 0f9329d · Campaña | condena_chapter_one_script.gd, condena_campaign.gd, condena_story_screen.gd y combat_scene.gd. Acciones del patio, talleres y celda, decisión moral y desenlace. Carga de la elección y montaje opcional de video por escena. | Tres recorridos con las opciones A, B y C, reputación −5, +10 y 0, vuelta al menú y carga tras elegir en los lavaderos. |
| 9c02b11 · Rivales | ai_el_flaco.gd, ai_preso_grande.gd, fighter.gd y campaign_bridge.gd. Lectura por ataque, guardia pesada, agarre resistente a interrupción y recuperación adicional al fallar. | Tres rondas con IA activa y valores normales de campaña. El jugador automatizado ganó contra El Chico y el Preso Grande y perdió contra El Flaco, con una semilla y una estrategia. |
| d4ecd2a · PC | pc_pause.gd, combat_scene.gd, tests/full_chapter.gd y tests/rival_rounds.gd. Menú, reanudación, pantalla completa y sonido persistentes, pausa, tutorial inicial y dibujo monocromático. | Cuatro pruebas de regresión, tres rutas integrales y tres rondas. Exportación Windows Desktop release x86_64 en Godot 4.2.2. Las tres rutas también llegaron al final cargando el paquete incrustado en el EXE desde Godot Linux. |

## Alcance de la validación

Los tests de rutas recorren el menú, ambos videos, cada interfaz de decisión, los selectores, los resultados y los guardados. En cada pelea ajustan la salud y la distancia y ejecutan un ataque para verificar impactos finales, victorias y derrotas. Las pruebas de rondas mantienen los atributos normales, la IA y el tiempo de campaña. El ensayo con entradas sintéticas verifica teclado y mando. La jugabilidad con mando físico, la reproducción audiovisual en equipos Windows y el equilibrio con personas siguen pendientes.

Para reproducir en Linux, importa el proyecto con Godot 4.2.2. Ejecuta cada script en una carpeta de datos temporal independiente. Un timeout o un mensaje SCRIPT ERROR invalida la prueba.

```bash
godot --headless --editor --import
for spec in campaign_smoke combat_smoke pc_chapter pc_counters; do
  XDG_DATA_HOME=$(mktemp -d) timeout 60 godot --headless --script "res://tests/$spec.gd"
done
for route in 0 1 2; do
  XDG_DATA_HOME=$(mktemp -d) CONDENA_TEST_ROUTE=$route timeout 60 godot --headless --script res://tests/full_chapter.gd
  XDG_DATA_HOME=$(mktemp -d) CONDENA_RIVAL=$route timeout 60 godot --headless --fixed-fps 60 --script res://tests/rival_rounds.gd
done
```

## Próxima etapa

Preparar los cinco fotogramas aprobados y montar los planos de 04, 05, 06, 07 y 09 según FLOW_CAPITULO_1.md. Las escenas ya son navegables mediante la interfaz narrativa. Preservar ambos MP4 iniciales y la independencia del combate 2D. Validar en Windows con teclado y mando físicos después del montaje. El experimento Tripo requiere referencias completas y una vía de generación autorizada bajo el presupuesto del proyecto.
