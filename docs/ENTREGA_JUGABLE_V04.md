# CONDENA — Entrega jugable v0.4 (16 de noviembre de 2026)

## Qué se implementó
- Golpes con colisión direccional, alcance, stamina, bloqueo y ruptura de guardia.
- Técnicas equipables antes del combate: jab/patada baja, cross/codazo, clinch/derribo.
- Amagues que gastan resistencia y exponen una recuperación breve.
- Esquiva física y **esquiva perfecta**: si el golpe coincide con la invulnerabilidad, abre oportunidad de contraataque.
- **Parada activa (parry)** de 160 ms contra golpes; los agarres la superan. Fallar deja recuperación. Acertar abre contraataque y aturde al atacante.
- Combos con impacto confirmado, ventana temporal, límite y reducción progresiva de daño. Bloqueos no suman combo.
- IA El Chico: distancias, recursos, guardia, esquiva, parada y amagues probabilísticos.
- HUD: barras de vida y resistencia, cronómetro, historial de acciones legibles, contador de combo, resumen de ganador y botón repetir.
- Arte provisional procedural: patio, ventanas con barrotes y siluetas de espectadores. No son sprites finales.
- Pruebas de humo en tests/combat_smoke.gd y workflow GitHub Actions (importación + assertions + escena).

## Controles
### Android táctil
- Flechas izquierda/derecha: movimiento
- JAB/PATADA BAJA: técnica ligera equipada
- CROSS/CODAZO: técnica fuerte equipada
- CLINCH/DERRIBO: técnica de agarre equipada
- BLOQUEO: mantener pulsado
- ESQUIVA, PARADA y AMAGUE: pulsación
- Antes de comenzar: CAMBIAR TÉCNICAS e INICIAR COMBATE
- Al terminar: REPETIR COMBATE

### Duelo local de dos jugadores (experimental)
- Antes de iniciar, pulsar **RIVAL: IA (CAMBIAR)** para activar **RIVAL: JUGADOR 2**.
- P1: A/D para desplazarse; J/K/L ataques; F parada; E amague; ESPACIO esquiva; SHIFT bloqueo.
- P2: flechas para desplazarse; 1/2/3 ataques; 4 esquiva; 5 parada; 6 amague; 0 bloqueo.
- Es prueba local en un mismo computador: **NO es PvP online**, no sincroniza por red ni admite dos teléfonos.

### Escritorio para pruebas
- A/D o flechas: caminar
- J: ligera; K: fuerte; L: agarre
- ESPACIO: esquiva; F: parada; E: amague
- SHIFT: bloqueo; ENTER: iniciar
- V: alternar vista limpia para retransmisión local (sin botones táctiles); J/K/L y demás teclas siguen funcionando

## Cómo probar gratis
1. Abrir el proyecto con Godot 4.2.2 (sin plugins de pago).
2. Ejecutar escena principal.
3. Seleccionar técnicas e iniciar combate.
4. Probar jab + jab, ataque contra bloqueo, agarre contra bloqueo, amague y parada de precisión.
5. Validación CLI: `godot --headless --path . --editor --import --quit`
6. Tests CLI: `godot --headless --path . --script res://tests/combat_smoke.gd`

## Límites y riesgos
- Código guardado, pero aún NO se verificó un run de Godot/Android exitoso en esta sesión.
- Existe duelo local experimental de dos jugadores en un teclado, pero NO hay networking PvP, rollback, replay determinista ni espectadores conectados; solo un registro local de eventos.
- Animaciones vectoriales provisionales, sin personajes finales, efectos de sonido ni hitboxes por fotograma.
- Balance 120/115 HP provisional, sujeto a pruebas.
- No se activaron anuncios, compras, cobros, servicios de pago ni generaciones con créditos.
- El workflow puede consumir minutos de Actions; revisar cuota gratuita del repositorio.

## Siguiente objetivo técnico
1. Verificar Godot CI y corregir cualquier error de parse/escena.
2. Construir animación 2D por estados con hitboxes sincronizadas y feedback de impactos.
3. Validar controles táctiles y FPS en Android real.
4. Profundizar combos por rutas y contrajuego de cada técnica.
5. Preparar APK de prueba sin activar monetización.
