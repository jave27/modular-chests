# Development

## Integration tests

The repository includes a Factorio integration-test mod under
`tests/integration-mod`. The tests run inside Factorio and currently cover:

- normal-quality chest merging;
- same-quality chest merging and inventory scaling;
- rejection of mixed-quality merges;
- preservation of item-stack quality;
- preservation of red and green circuit wires during both initial merging and
  later expansion;
- vertical steel chest merging, expansion, inventory capacity, and item retention;
- circuit connector graphics and merged-chest construction item metadata.

Run the suite from the repository root:

```powershell
./scripts/test.ps1
```

If Windows PowerShell blocks local scripts, use a process-scoped bypass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test.ps1
```

The script:

1. detects Factorio 2.0 or 2.1 from the selected executable;
2. calls `scripts/package.ps1` to build the matching mod archive;
3. creates an isolated directory under `.test-output/<game-version>-<mod-set>`;
4. loads the packaged mod and the integration-test mod;
5. creates a temporary map, causing the assertions in the test mod to run;
6. checks the exit code and success marker, then prints `PASS` or the failure log.

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

The harness supports Windows PowerShell 5.1 and PowerShell 7, including portable
Linux headless installations. Factorio itself is the only external program
required. The default configuration enables `quality` for quality assertions.
Choose `-ModSet Base` to test without expansion mods or `-ModSet SpaceAge` to
test with the full expansion. Quality assertions run when `quality` is enabled.

Run each configuration against **both** game executables before release:

```powershell
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.0\bin\x64\factorio.exe" -ModSet Base
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.0\bin\x64\factorio.exe" -ModSet Quality
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.0\bin\x64\factorio.exe" -ModSet SpaceAge
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.1\bin\x64\factorio.exe" -ModSet Base
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.1\bin\x64\factorio.exe" -ModSet Quality
./scripts/test.ps1 -FactorioExe "D:\Factorio-2.1\bin\x64\factorio.exe" -ModSet SpaceAge
```

Each configuration explicitly enables or disables the bundled mods, so a test
cannot silently pick up Space Age from an existing player configuration. Logs,
the generated mod list, packaged ZIP, and temporary save remain in that run's
output directory.

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

Factorio's `factorio_version` field accepts one game major version, so a single
archive cannot declare both 2.0 and 2.1. Keep `info.json` on the 2.0 release line
and share all Lua sources. The package script stamps the target game version,
base dependency, mod version, and latest changelog entry in the archive only.
Both release lines use the source version's patch number: source `2.0.19`
produces mod `2.0.19` for Factorio 2.0 and mod `2.1.19` for Factorio 2.1.

Build both packages from the repository root:

```powershell
./scripts/package.ps1 -FactorioVersion 2.0
./scripts/package.ps1 -FactorioVersion 2.1
```

The ZIPs appear in ignored `dist/`; `-OutputDirectory` selects another location.
The integration harness uses this same packager. Only mod assets are included,
and ZIP entries always use `/` for Windows, Linux, and macOS. Build published
releases from a clean worktree and run the full matrix above.
