# Compilación y distribución

GNU Make y Python 3.10 o posterior ejecutan las mismas fases en local y en
[GitHub Actions](../../.github/workflows/sourcemod-build.yml).

```sh
make deps-smx
make build-smx
make package-smx
make release
make validate-artifact
```

- `deps-smx` descarga `spcomp` y sus includes en `.deps/smx/`. `SOURCEMOD_VERSION` selecciona la rama publicada de SourceMod. El valor predeterminado es `1.12` y el build concreto depende del SDK descargado.
  `SPCOMP` permite seleccionar un compilador ya instalado.
- `build-smx` deja los binarios y recursos en `.build/smx/` y el diagnóstico en
  `.build/build-smx-compile.log`.
- `package-smx` prepara y valida el árbol en `.build/package-smx/`.
- `release` prepara `dist/sourcemod/artifact/`, lo valida y genera el ZIP local
  en `dist/release/`. `RELEASE_BASENAME` permite cambiar el nombre.
- `validate-artifact` compara el árbol final con el mapa y las fuentes actuales.
  `SOURCEMOD_ARTIFACT_DIR` permite seleccionar otro árbol.
- `clean` limpia `.build/` y `dist/`. `clean-all` también limpia `.deps/`.

Desde otro directorio se puede usar `make -f "/ruta/al repositorio/Makefile" <target>`.
Las rutas relativas de las opciones de build y paquete se resuelven desde el
repositorio. Las variables se pueden pasar a Make o heredar del entorno.

## Contenido

El [mapa de paquete](../../scripts/package/package-map.json) declara los
entrypoints, sus destinos y los archivos que acompañan a cada plugin.

- `AFKReadyup.sp` → `addons/sourcemod/plugins/AFKReadyup.smx`


El ZIP incluye las fuentes SourcePawn de producto, los recursos seleccionados, el
`README.md`, `LICENSE` y `NOTICES.md`. El mapa, las guías técnicas
y el log de compilación se consultan en el repositorio o en el resultado del build.

## Dependencias

El build utiliza los includes de SourceMod y los que están versionados en
`addons/sourcemod/scripting/include/`. Consulta [Requisitos de AFK on ReadyUp](../../README.md#instalación)
para los proveedores del juego y los requisitos de ejecución.

## CI

GitHub Actions usa la variable de organización `SOURCEMOD_VERSION` para
seleccionar la rama del SDK. La preparación falla si la variable falta o tiene
un formato distinto de `mayor.menor`.

GitHub Actions prepara el host, ejecuta las fases de Make y guarda el ZIP como artefacto. El job `publish-channel` toma ese ZIP y publica desde `main` o `develop` con permisos de escritura. El workflow también conserva la rama heredada `master` para Latest. Las pull requests generan artefactos temporales.
