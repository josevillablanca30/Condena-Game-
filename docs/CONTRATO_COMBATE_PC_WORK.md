# CONDENA — Contrato de combate PC v0.1 (diseño, no implementación)

## Decisiones aprobadas
- Plataforma comercial prioritaria: PC. Android en pausa. Motor: Godot 4; no reiniciar proyecto.
- 1v1 sin poderes: técnica física creíble, lectura del rival, tres técnicas equipables y combinables.
- Acciones básicas siempre disponibles: movimiento, ataque, guardia, esquiva, amago y respuesta defensiva. Las tres ranuras no deben bloquear la defensa esencial.
- Cada técnica requiere alcance, anticipación, contacto, recuperación, coste, contraataque y sinergias verificables. Ninguna combinación debe ser invencible.
- Dirección artística manga seinen monocroma; conservar campaña aprobada «EL POLLO» de nueve escenas.
- Producción adicional $0: Godot, GitHub y herramientas disponibles; fotogramas preparados por ChatGPT, clips de hasta 10 s generados por el usuario con Flow. No generar nuevas APK por ahora.
- Tienda web futura con Mercado Pago bajo estructura comercial autorizada; no activar pagos ni asumir cumplimiento de plataformas sin revisión.

## Estado REAL del código existente (pendiente de validar en Godot)
`src/combat/fighter.gd` ya incluye seis movimientos en tres ranuras **restringidas por categoría**:
- light: jab / low_kick
- heavy: cross / elbow
- grapple: clinch / takedown

Esto **todavía no equivale** a tres habilidades libremente combinables. No presentar el prototipo actual como el sistema final. El motor existente tiene costes de resistencia, alcance, ventanas de parada, esquiva, amago, recuperación y agarres; debe conservarse y evolucionar sin romper la campaña.

## Matriz inicial de interacción (propuesta de diseño, NO habilidades implementadas)
| Técnica | Uso | Respuesta posible | Riesgo de quien la ejecuta |
|---|---|---|---|
| Jab | Medir distancia, interrumpir | Guardia, desvío temporizado | Exponerse a contraataque por repetición |
| Patada baja | Castigar desplazamiento | Retirada, anticipación y respuesta rápida | Recuperación mayor si falla |
| Cross | Castigo potente | Esquiva lateral o parada precisa | Alta recuperación y resistencia |
| Codazo | Intercambio cercano | Mantener distancia | Muy corto alcance |
| Amarre | Controlar al rival cercano | Evitar entrada, separar el cuerpo | Vulnerable al fallar entrada |
| Derribo | Romper equilibrio | Distancia, anticipación de entrada | Gran coste y recuperación |
| Amago | Provocar reacción | Esperar, observar, no gastar defensa | No hace daño y cede iniciativa |
| Esquiva | Evitar contacto y abrir contra | Amago y castigo al terminar esquiva | Ventana de recuperación |
| Parada | Desviar golpe leído | Agarre o amago | Ventana temporal muy breve |

Las respuestas no deben ser automáticas: validar distancia, tiempo, estado y dirección. Balance numérico pendiente de pruebas.

## Próximo bloque de implementación para Work
1. Revisar estado remoto de rama `work/condena-combate-v02-20261107` y PR #1; no repetir auditoría general ni fusionar.
2. Preparar controles PC teclado/mando, manteniendo las acciones básicas.
3. Separar **tres ranuras equipables** de acciones básicas. Definir contrato de datos para técnicas, sin crear docenas de animaciones todavía.
4. Implementar prueba de 1v1 local con lectura de ataques, recuperación, defensa y contramedidas; mantener IA actual y campaña sin alteraciones.
5. Crear pruebas automatizadas de selección válida, costes, vulnerabilidad, respuestas y no regresión de escenas 03/05/08.
6. Preparar exportación PC solo cuando la mecánica sea suficientemente sólida; no ejecutar builds costosos sin necesidad.

## Guion y audiovisuales
Fuente narrativa: «Documento Maestro del Proyecto CONDENA (1).md» de la biblioteca del usuario. **No parafrasear ni sustituir diálogos aprobados**. Las dos primeras cinemáticas de Flow fueron compartidas en la conversación: `1000153316.mp4` (revelación del protagonista, escena 01) y `1000153319.mp4` (El Chico en comedor, escena 02). Se consideran **candidatas**, no integradas ni validadas cuadro a cuadro. Recuperar los archivos originales antes de integrar; no regenerar caras o personajes.

Escena 02: conservar las tres respuestas A/B/C, su reputación y la réplica exacta del guion maestro. Escena 03: primer combate contra El Chico; tanto victoria como derrota permiten continuar según el guion aprobado.

## Criterios de salida
- PC teclado/mando con inputs comprobados.
- Tres ranuras configurables y técnicas con contramedidas documentadas.
- Ningún bloqueo narrativo en escena 02→03.
- Sin pagos activados, sin APK nuevo, sin gastos adicionales.
