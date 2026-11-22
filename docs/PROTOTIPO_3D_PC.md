# Referencias para el prototipo 3D

| Personaje | Archivo original | Referencia visible |
| --- | --- | --- |
| El Chico | assets/cinematics/originals/1000153319.mp4 | 0:01 para la camisa, postura y proporción del torso; 0:07 para pelo, cejas y rasgos. |
| Protagonista | assets/cinematics/originals/1000153316.mp4 | 0:02 para la silueta sentada y la camisa; 0:07 para el rostro y el pelo. |

El repositorio trae un manifiesto de animaciones 2D y dibuja a los luchadores en código. No contiene una malla ni un esqueleto aprobados. Los dos videos priorizan el torso. Para cerrar una malla fiel faltan referencias aprobadas de espalda, piernas y calzado.

En el entorno de esta entrega la herramienta de línea de comandos de Tripo no está instalada. No se envió material ni se inició una generación. No hay un GLB, rig ni animaciones 3D validados.

Primera prueba al disponer de modelo autorizado: importar El Chico en una escena aislada de Godot 4.2.2, verificar escala, pivote al suelo, Skeleton3D, pesos de hombros y manos en guardia, materiales monocromos y lectura a distancia de juego. Sincronizar una animación de ataque con la ventana de impacto existente. Conservar el controlador y las colisiones 2D hasta evaluar el resultado.
