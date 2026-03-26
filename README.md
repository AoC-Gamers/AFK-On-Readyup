## AFK on ReadyUp

Este complemento esta destinado a mover al grupo de espectador a los jugadores que esten AFK en el periodo de readyup. Depende de que este cargado antes de Confogl.

## Artefactos

El repositorio incluye un flujo de GitHub Actions en .github/workflows/sourcemod-build.yml que:

- compila AFKReadyup.sp
- valida la estructura del artefacto generado
- empaqueta un zip instalable con plugins, scripting, traducciones y cfg

El zip resultante queda disponible como artifact del workflow.
