# Vínculo

Addon de WoW **Forever** (interfaz `16001`, cliente 1.60.1) para cazadores: diario de la mascota.
Lua puro, sin librerías (sin Ace3). Namespace local `ns`. SavedVariables: `VinculoDB`.

- Código: `Vinculo/` (orden de carga en `Vinculo.toc`: Locale → Core → Achievements → Extras → UI)
- Tests fuera del juego: `node _luatest/run.js` (fengari + stubs en `_luatest/test.lua`)
- Plan y checklist de prueba en el juego: `docs/ROADMAP.md`
- Textos en `Locale.lua` (esES y enUS): toda cadena visible va ahí.

Para cualquier API del juego, usa la skill `vinculo-forever` antes de escribir código.

## Forma de trabajar (ahorro de tokens)

- Responde corto y en español. Sin resúmenes de lo que acabas de hacer ni explicaciones no pedidas.
- No leas archivos enteros si basta con buscar (Grep) o leer un rango.
- No releas un archivo después de editarlo.
- Ignora `_luatest/node_modules`, `releases/`, `*.rar` y `logo/`.
- Cambios mínimos: no reformatees ni reescribas código que no toca la tarea.
- Si la tarea es de investigar, delega a un subagente y trae solo la conclusión.
- Tras cambiar Lua, ejecuta los tests; no digas que funciona en el juego sin que yo lo confirme.
