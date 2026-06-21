# Development

## Integration tests

The repository includes a Factorio integration-test mod under
`tests/integration-mod`. The tests run inside Factorio and currently cover:

- normal-quality chest merging;
- same-quality chest merging and inventory scaling;
- rejection of mixed-quality merges;
- preservation of item-stack quality;
- preservation of red and green circuit wires during both initial merging and
  later expansion.

Run the suite from the repository root:

```powershell
./scripts/test.ps1
```

If Windows PowerShell blocks local scripts, use a process-scoped bypass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test.ps1
```

The script:

1. reads the mod name and version from `info.json`;
2. packages the working tree with portable `/` ZIP entry separators;
3. creates an isolated Factorio write-data directory under `.test-output`;
4. loads the packaged mod and the integration-test mod;
5. creates a temporary map, causing the assertions in the test mod to run;
6. prints `PASS` or the relevant Factorio log when a test fails.

Generated files are ignored by Git.

### Selecting Factorio

Set `FACTORIO_EXE` when Factorio is not installed in a location the script can
discover:

```powershell
$env:FACTORIO_EXE = "D:\Games\Factorio\bin\x64\factorio.exe"
./scripts/test.ps1
```

You can also pass the executable explicitly:

```powershell
./scripts/test.ps1 -FactorioExe "D:\Games\Factorio\bin\x64\factorio.exe"
```

The harness supports Windows PowerShell 5.1 and PowerShell 7. Factorio itself
is the only external program required. The full suite enables Factorio's
`quality` expansion mod because several tests exercise quality behavior.

## Adding integration tests

Add focused assertions to `tests/integration-mod/control.lua`. Use separate map
areas for independent scenarios so one merge cannot influence another.

For a larger or experimental test, copy
`tests/templates/test-mod`, give it a unique mod name, and add it to the
generated mod list in `scripts/test.ps1`.

Tests should:

- use Factorio runtime APIs rather than duplicating mod logic;
- call `assert` with a useful failure message;
- avoid machine-specific paths and player state;
- write the success marker only after every assertion passes.

## Release packaging

The test script's generated ZIP is suitable for validating archive layout, but
release files should still be built from a clean worktree. ZIP entries created
by the script always use `/`, making them valid on Windows, Linux, and macOS.
