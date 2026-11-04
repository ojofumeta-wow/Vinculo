const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring } = require("fengari");

const addonDir = path.resolve(__dirname, "..", "Vinculo").replace(/\\/g, "/");
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const src = fs.readFileSync(path.join(__dirname, "test.lua"));
if (lauxlib.luaL_loadbuffer(L, src, null, to_luastring("test.lua")) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1));
  process.exit(1);
}
lua.lua_pushstring(L, to_luastring(addonDir));
if (lua.lua_pcall(L, 1, 0, 0) !== lua.LUA_OK) {
  console.error(lua.lua_tojsstring(L, -1));
  process.exit(1);
}
