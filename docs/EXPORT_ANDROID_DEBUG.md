# CONDENA — Preparación APK Android sin costos

## Estado
Se agregó `export_presets.cfg` con preset **Android Debug**, arm64, paquete provisional `com.somosvillablanca.condena`, nombre CONDENA, versión 0.5.0 y sin permisos de Internet solicitados. **Esto no es una APK construida ni validada.** No hay pagos, servicios de terceros ni credenciales de producción.

## Exportación local con Godot 4.2.2
1. Instalar Godot 4.2.2 y sus plantillas de exportación Android oficiales (gratuitas).
2. Instalar Android SDK/JDK compatibles y configurarlos en Editor > Editor Settings > Export > Android.
3. Abrir el proyecto y confirmar que importa sin errores.
4. Ejecutar `godot --headless --path . --editor --import --quit` y `godot --headless --path . --script res://tests/combat_smoke.gd`.
5. Crear la carpeta `build`.
6. Exportar debug desde Godot: Proyecto > Exportar > Android Debug > Exportar proyecto, o `godot --headless --path . --export-debug "Android Debug" build/CONDENA-debug.apk`.
7. Instalar la APK en un Android de prueba, revisar pantalla horizontal 1280×720, botones táctiles, combos, audio (aún no implementado) y rendimiento.

## Restricciones
- No generar firma de lanzamiento ni subir a Google Play sin aprobación.
- No activar cobros, anuncios, servicios de analítica ni cuentas remotas.
- No asumir que el preset exporta correctamente hasta ejecutar Godot con Android SDK y plantillas instaladas.
- En Godot, la firma debug y la configuración SDK deben estar disponibles en el entorno que haga la exportación.
- El 1v1 local es solo para teclado; Android por ahora permite jugador contra IA.

## Criterio de aceptación de la primera APK
- Abre en dispositivo Android real, sin errores críticos.
- No se sale de la pantalla ni recorta botones de movimiento/defensa.
- Puede comenzar, ganar o perder, y repetir.
- Las técnicas y el bloqueo responden al tacto.
- No solicita permisos innecesarios ni genera compras.
