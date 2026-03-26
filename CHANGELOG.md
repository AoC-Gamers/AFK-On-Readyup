# Changelog

Todos los cambios importantes de este proyecto se documentan en este archivo.

## [Unreleased]

## [1.2.0] - 2026-03-26

### Added
- Flujo de GitHub Actions para compilar el plugin y generar artefactos instalables.
- Workflow de release por tags para publicar el zip en GitHub Releases.
- Scripts de CI para build, validacion del artefacto y empaquetado.
- API publica inicial para integraciones via la libreria afkreadyup, con natives de consulta y forwards pre/post de enforcement.

### Changed
- El artifact instalable conserva AFKReadyup.sp y el include publico afkreadyup.inc, y deja fuera includes usados solo para compilar.

## [1.1.6] - 2025-05-11

### Changed
- Release de mantenimiento 1.1.6.

## [1.1.5] - 2025-05-09

### Changed
- Mejoras y correcciones generales en la logica de AFK durante readyup.
- Ajustes de late load para inicializar correctamente el plugin cuando carga tarde.
- Correccion del manejo de timers relacionado con TIMER_FLAG_NO_MAPCHANGE.

## [1.1.0] - 2024-03-15

### Added
- Actualizacion principal del plugin a la serie 1.1.

### Fixed
- Correcciones iniciales del comportamiento del plugin y ajustes menores del proyecto.