# AFK on ReadyUp

AFK on ReadyUp es un plugin SourceMod para Left 4 Dead 2 orientado a servidores competitivos que usan la fase de readyup. Su funcion es detectar jugadores inactivos durante esa fase, moverlos a espectador cuando agotan el tiempo AFK configurado y, opcionalmente, expulsarlos del servidor si permanecen en espectador demasiado tiempo.

El plugin esta pensado para entornos donde exista una integracion de readyup y donde el flujo de partida dependa de la fase previa a live.

## Comportamiento

Mientras la ronda esta en readyup, el plugin:

- inicializa un contador AFK para cada jugador humano en Survivor o Infected
- reinicia el contador cuando detecta actividad valida
- puede ignorar a jugadores que ya marcaron ready
- mueve al jugador a espectador cuando su contador llega a cero
- puede iniciar un kick diferido despues del move a espectador
- muestra un footer opcional en el panel de readyup con el menor tiempo AFK restante entre los jugadores seguidos

Las fuentes de actividad que hoy resetean el contador incluyen:

- movimiento real del jugador
- cambio de angulos de camara
- chat
- acciones de juego como shove, disparo, recarga, uso y salto
- comandos de espectador y otros comandos observados por el listener
- cambios de ready y unready
- entrada al servidor mientras el readyup ya esta activo

Cuando la ronda pasa a live o termina el mapa, el tracking se detiene y se limpia todo el estado interno del plugin.

## Dependencias

Requeridas en runtime:

- SourceMod
- un sistema de readyup compatible con el plugin

Usadas para compilar, pero no necesarias como parte del artifact instalable:

- includes estandar de SourceMod
- dependencias de compilacion del ecosistema SourceMod usadas por el proyecto

## Instalacion

Instalacion manual:

1. Copia el binario compilado del plugin al directorio de plugins del servidor.
2. Copia los archivos de traduccion al directorio de traducciones de SourceMod.
3. Si otro plugin va a integrarse con esta extension, copia tambien su include publico al arbol de includes de compilacion.
4. Inicia el servidor o recarga el plugin.

En el primer arranque, SourceMod generara la configuracion automatica del plugin mediante su mecanismo habitual de autoexec para ConVars.

## Configuracion

La configuracion del plugin gira alrededor de estos grupos funcionales:

- habilitacion general del sistema AFK
- nivel de debug y verbosidad operativa
- politica para ignorar o no a jugadores marcados como ready
- tiempo AFK permitido antes de mover a espectador
- visibilidad del contador para jugadores y panel de readyup
- tiempo de gracia antes de un kick automatico despues del move a espectador

Comportamientos relevantes:

- si el tiempo de gracia para kick esta desactivado, el plugin nunca expulsa automaticamente
- si la politica de ignore para jugadores ready esta activa, un jugador ready puede quedar fuera del seguimiento AFK hasta volver a unready
- si el juego esta pausado, el timer AFK no sigue descontando

Los nombres exactos de las ConVars pueden cambiar entre versiones, asi que conviene tomar como referencia el archivo de configuracion autogenerado por el propio plugin en la instalacion objetivo.

## Artefactos

El repositorio incluye un flujo de CI que:

- compila el plugin
- valida la estructura del artifact generado
- empaqueta un zip instalable listo para distribuir

El artifact instalable conserva solo el contenido propio y publico del plugin:

- binario compilado
- codigo fuente principal distribuible
- include publico para integraciones
- traducciones del plugin

No se incluyen dependencias usadas solo para compilar.

## API publica

El plugin expone un include publico para integraciones con otros plugins.

La superficie publica esta organizada en dos bloques:

- consultas y utilidades para saber si el tracking AFK esta activo, leer estado por jugador, consultar tiempos restantes y resetear seguimiento cuando corresponda
- eventos de extension para reaccionar al inicio o fin del tracking, al move a espectador y al kick diferido

Los eventos previos al enforcement permiten cancelar o reemplazar el comportamiento por defecto desde otro plugin, mientras que los eventos posteriores sirven para auditoria, logging o integraciones auxiliares.

Como los nombres exactos de natives y forwards pueden evolucionar entre versiones, la referencia canonica de integracion debe ser siempre el include publico distribuido con el plugin.

## Desarrollo

El proyecto separa el codigo principal del plugin de su include publico para integraciones.

Para revisar cambios recientes y compatibilidad, consulta CHANGELOG.md.
