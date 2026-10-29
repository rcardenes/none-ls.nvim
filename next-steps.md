# none-ls.nvim — plenary removal: session state / next steps

Saved so the session can be interrupted and resumed later.
Repo root: `/home/javi/src/nvim-plugins/none-ls.nvim`. User on Neovim 0.12.

---

## Objective
- Remove all `plenary.nvim` dependencies from `none-ls.nvim` — runtime, tests, CI, packaging, and docs — replacing them with native Neovim 0.12 APIs, an internal async shim, `mini.test`, and vendored test libraries.

## Important Details
- Locked decisions:
  - Replace `plenary.async` with internal `lua/null-ls/async.lua`.
  - Replace `plenary.busted` with `mini.test` plus `test/busted_compat.lua`.
  - Vendor `luassert`, `say`, and `mini.test` under `test/deps/lua/`.
  - Remove `plenary.nvim` from runtime, tests, CI, docs, packaging, and editor config.
- Test runner:
  - `make test` runs each `test/spec/**/*_spec.lua` file in a separate headless Neovim process.
  - `make test-file FILE=test/spec/...` runs one spec file.
  - `test/minimal_init.lua` uses vendored `mini.test`, `luassert`, and `say`.
  - `test/debug_init.lua` still uses `M.load` only for `jbyuki/one-small-step-for-vimkind`.
- Non-fatal test noise fixed:
  - `diagnostics_spec.lua` `E5108` from `luaeval()` was caused by the default statusline calling `next(vim.diagnostic.count())` while `vim.diagnostic` was mocked.
    - Fixed by setting `vim.o.laststatus = 0` and `vim.o.ruler = false` in test inits.
  - `formatting_spec.lua` scheduled `nvim_buf_delete` invalid buffer error was caused by a `vim.schedule` callback running after `mock.revert(vim.api)`.
    - Fixed by flushing scheduled callbacks with `vim.wait(10, ...)` in `after_each` before reverting the `vim.api` mock.
- Full suite status:
  - `make test` exits `0`.
  - All spec files report `Fails (0)`.
  - No `E5108`, `vim.schedule callback`, or `Invalid buffer id` errors remain in the local full-suite log.

## Work State
### Completed
- Replaced `plenary.async` with internal `lua/null-ls/async.lua`.
- Fixed Lua 5.1 / Neovim compatibility issues in the async shim and test adapter:
  - unavailable `table.pack` / `table.unpack` / `vim.tbl_pack` replaced with local helpers.
  - async `step` self-reference bug fixed.
  - `rotate()` semantics aligned with Plenary.
  - `coroutine.resume` wrapper in `test/busted_compat.lua` now forwards all resume return values.
- Made `test/busted_compat.lua` run each `it` in a coroutine and wait for completion when the test yields.
- Fixed `test/spec/sources_spec.lua` collection-time `mock_raw_source` nil bug.
- Vendored test libraries:
  - `test/deps/lua/luassert/`
  - `test/deps/lua/say/`
  - `test/deps/lua/mini/test.lua`
- Updated REUSE metadata for vendored `luassert`, `say`, and `mini`.
- Removed `plenary.nvim` from:
  - `test/minimal_init.lua`
  - `test/debug_init.lua`
  - `Makefile`
  - `.github/workflows/build.yml`
  - `.github/workflows/luarocks.yml`
  - `README.md`
  - `doc/CONFIG.md`
  - `doc/TESTING.md`
  - `doc/null-ls.txt`
  - `scripts/minimal_init.lua`
  - `.nvim.settings.json`
- Ran `make autogen` to regenerate `doc/BUILTINS.md`, `doc/builtins.json`, and builtin metadata.
- Removed local `.tests/` cache with `make clean`.
- Verified full test suite passes cleanly.

### Active
- Optional local lint/REUSE verification is limited because `pre-commit`, `stylua`, `selene`, `actionlint`, and `reuse` are not installed in this environment.
- `next-steps.md` was updated to reflect the current state.

### Blocked
- None.

## Next Move
1. If available, run the normal lint/REUSE checks:
   - `make check`
   - `reuse lint`
   - `actionlint`
2. If changes are approved, commit them only if the user explicitly asks.

## Relevant Files
- `lua/null-ls/async.lua`
- `test/busted_compat.lua`
- `test/minimal_init.lua`
- `test/debug_init.lua`
- `test/deps/lua/mini/test.lua`
- `test/deps/lua/luassert/`
- `test/deps/lua/say/`
- `test/spec/formatting_spec.lua`
- `test/spec/diagnostics_spec.lua`
- `test/spec/sources_spec.lua`
- `Makefile`
- `.github/workflows/build.yml`
- `.github/workflows/luarocks.yml`
- `README.md`
- `doc/CONFIG.md`
- `doc/TESTING.md`
- `doc/null-ls.txt`
- `scripts/minimal_init.lua`
- `.nvim.settings.json`
- `REUSE.toml`
