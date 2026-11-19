# Seguimiento AFK durante readyup

Durante readyup, el plugin cuenta la inactividad de cada jugador humano de Survivor e Infected. El movimiento, la cámara, el chat, las acciones de juego, los comandos observados y los cambios de ready reinician el seguimiento. También se incorporan los jugadores que entran con readyup activo.

Cuando se agota el tiempo, el jugador pasa a espectador. Si hay un tiempo de gracia configurado, se programa una expulsión. La cuenta AFK se detiene mientras el juego está pausado y el seguimiento se limpia al pasar a live o terminar el mapa.

## Configuración

| ConVar | Predeterminado | Comportamiento |
|---|---:|---|
| `sm_afk_enable` | `1` | Activa el plugin. |
| `sm_afk_debug` | `0` | Activa mensajes de depuración. |
| `sm_afk_ignore` | `1` | Excluye a jugadores marcados como ready. |
| `sm_afk_time` | `90` | Segundos de inactividad antes de mover a espectador. |
| `sm_afk_footer` | `1` | Muestra el menor tiempo restante en el panel de readyup. |
| `sm_afk_show` | `10` | Umbral para mostrar el contador al jugador. Usa `0` para desactivarlo. |
| `sm_afk_kick_delay` | `360` | Segundos de gracia después del traslado. Usa `0` para desactivar la expulsión. |
