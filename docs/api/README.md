# Integración SourcePawn

Incluye [`afkreadyup.inc`](../../addons/sourcemod/scripting/include/afkreadyup.inc) para consultar el seguimiento global y por jugador, leer el tiempo restante o reiniciar un contador. El include también declara los forwards del inicio y fin del seguimiento, el traslado a espectador y la expulsión diferida.

Los forwards previos permiten intervenir en el traslado o la expulsión. Usa los posteriores para reaccionar a una acción ya aplicada.
