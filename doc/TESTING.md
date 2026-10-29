# Testing

- The test suite includes unit and integration tests.
- It uses `mini.test` and vendored copies of `luassert` and `say` under
  `test/deps/lua`, so no external test plugins are required.
- `test/minimal_init.lua` is the minimal init used by the test runner.
- `test/debug_init.lua` is an optional init for debugging with
  `one-small-step`.

## Suite

- Run `make test` in the root of the project to run the test suite.

## Single-file tests

- Run `FILE=test/spec/file_spec.lua make test-file` to run tests from a specific
  file, for example:

```sh
FILE=test/spec/e2e_spec.lua make test-file
```
