# Build System

Este repositorio usa un flujo SourceMod unificado para desarrollo local y CI.

## Objetivo

El mismo proceso debe servir para:

- compilacion local en Windows
- compilacion local en Linux o WSL
- compilacion en GitHub Actions

La fuente real del flujo es Python. `make` actua como interfaz corta y el CI reutiliza los mismos comandos.

## Targets

El `Makefile` expone cuatro etapas:

- `make deps-smx`
- `make build-smx`
- `make package-smx`
- `make release`

### `deps-smx`

Descarga el paquete de SourceMod necesario para obtener `spcomp` y sus includes.

### `build-smx`

Compila los plugins definidos en [plugin-package-map.json](../plugin-package-map.json) y deja el output intermedio en `.build/smx`.

### `package-smx`

Arma el arbol instalable intermedio en `.build/package-smx`.

### `release`

Genera el artifact final en `dist/sourcemod/artifact` y empaqueta el zip en `dist/release/`.

## Manifiesto

[plugin-package-map.json](../plugin-package-map.json) define dos cosas:

- que plugins se compilan y en que bucket de `plugins/`
- que archivos runtime se incluyen en el artifact

En este repo:

- `build.plugins.root` compila `AFKReadyup`
- `artifact.addons.sourcemod.scripting` publica el `.sp` distribuible y el include publico
- `artifact.addons.sourcemod.translations.all` copia todas las traducciones del plugin

## CI

El workflow principal separa tres jobs:

- `deps-smx`
- `build-smx`
- `release`

`release` absorbe el empaquetado liviano y publica el zip final. Los artifacts intermedios quedan con retencion corta.

## WSL

Si el repo se compila desde WSL sobre `/mnt/...`, el builder puede usar un workspace temporal Linux para evitar el costo de I/O sobre el filesystem montado de Windows.

## Comandos utiles

```bash
make deps-smx
make build-smx
make package-smx
make release
```
