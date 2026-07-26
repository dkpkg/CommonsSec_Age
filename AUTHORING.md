# Authoring checklist — CommonsSec_Age

The **bundles, module rules, distribution skeleton, and CI are authored**. What
remains carries dk0-generated content-addressed value-ids or is hardware-gated, so
it must be produced with dk0 + the maintainer's YubiKeys — not hand-written.
Template package: `Y:\source\CommonsLang_DotNet` (a prebuilt-runtime bundle with a
single `CommonsBase_Std` dependency). Model: `dksdk-coder/plans/signing/`.

## Pinned upstreams (DONE)

Resolved from the GitHub release-asset digests (`gh api .../releases/latest --jq
'.assets[].digest'`) — real SHA-256 + size, no download needed:

- **age 1.3.1** — github.com/FiloSottile/age
- **age-plugin-yubikey 0.5.1** — github.com/str4d/age-plugin-yubikey (no Linux binary)
- **age-plugin-fido2-hmac 0.5.0** — github.com/olastor/age-plugin-fido2-hmac

`supported_slots()` = the intersection all three ship:
**Windows_x86_64, Darwin_x86_64, Darwin_arm64** (Linux dropped — yubikey ships
none). Archive internal layouts were inspected (`tar -tf`) to get the declared
`paths` right.

## Done in this repo

- `etc/dk/v/CommonsSec_Age/{Age,AgePluginYubikey,AgePluginFido2Hmac}.Bundle.values.jsonc`
  — real per-ABI `{path, checksum.sha256, size, origin}`.
- `etc/dk/v/CommonsSec_Age/Age.values.lua` — `supported_slots()`, per-slot file
  lists, `form_values_windows/unix`, `rules.Files`, and the `uirules.Age` runner.
- `.github/workflows/distribute-0.1.yml` — 3-ABI matrix, `dk-distribution`
  environment, combine→attest→release.
- `dist/any.u` — the `run-rule` invocation (object value-ids to be dk0-generated).
- `dk.u`, `README.md`, `.gitattributes`, `.gitignore`.

## Remaining (dk0 / hardware-gated)

1. **Launchers**: copy `dk0` + `dk0.cmd` from `dksdk-coder/ext/dk` (or a sibling
   dkpkg package).
2. **Workspace**: `dk0 add github-l2 dkpkg/CommonsBase_Std` then `dk0 update` to
   fill `dk.u`'s `## workspace` block and `etc/dk/i/*.values.json`.
3. **Bundles are already validated** (done): `dk0 -I etc/dk/v
   --trust-local-package CommonsSec_Age get-bundle CommonsSec_Age.Age.Bundle@1.3.1
   -d target/agebundle` (and the two plugin bundles) all download the real
   archives and verify the pinned SHA-256. Re-run if you re-pin.
4. **prepare-version (hardware-gated)**: after provisioning the recovery YubiKeys
   (`dksdk-coder/skills/manage-signing-recipients/SKILL.md`), run
   `dksdk-coder/scripts/prepare-dkpkg-version.ps1 -Package CommonsSec_Age -Spdx
   BSD-3-Clause`. The driver materializes `age` from this checkout via `get-asset`
   (no hand-install needed even for this package's own first prepare-version -- see
   the age-sourcing note below).
5. **Distribute -- this is where `Age.values.lua` is first exercised.** A brand-new
   local rule is NOT runnable via a bare `run-function`; it becomes runnable only
   after the first `distribute` build. `dk0 distribute` (the `diskuv/dk-distribute`
   CI action, per `.github/workflows/distribute-0.1.yml`) evaluates `dist/any.u`,
   runs `CommonsSec_Age.Age.Files` per ABI, records the `\dk.object(...)` value-ids
   in `dist/any.u`, and produces `dk-dist/`. **Expect to fix `Age.values.lua` here**
   (e.g. the Darwin binaries extract without +x -- reproducible-zip limitation; if
   consumers need them executable, add a chmod continuation to `rules.Files` as
   `SDK.values.lua`'s `workaround_make_dotnet_executable` does; the Windows host,
   the only slot the signing flow strictly needs, is unaffected).
6. **Release + CI validation**: tag `0.1.0`; validate via
   `dksdk-coder:github-actions-validation`. After release, `dk0 add github-l2
   dkpkg/CommonsSec_Age` makes `Age.Files` runnable for consumers (and for the
   signing driver's auto-materialize).

## Refresh (later versions)

Re-pin by re-running `gh api repos/<owner>/<repo>/releases/latest --jq
'.assets[] | {name, size, digest}'` for each tool, updating the three bundle
files' versions/paths/checksums and `Age.values.lua`'s `asset_for` + versions.

## Bootstrap / age sourcing (no hard cycle)

Building/releasing this package uses signify, not age (dk0 does the distribution
signing), so nothing about producing CommonsSec_Age needs age at build time. The
signing driver `prepare-dkpkg-version.ps1` materializes `age` with `dk0 get-asset`
(each Windows zip auto-extracted into a per-tool subdir; plugin dirs put on PATH).
**Validated:** `get-asset` reads bundle data and works from a local checkout before
the package is released, so even CommonsSec_Age's own first `prepare-version` gets
its `age` from this checkout -- no hand-install.

Note the distinction: the module's `Files` **rule** does NOT resolve pre-release
(a fresh rule needs the first `distribute` build; see step 5), so the driver
deliberately uses `get-asset`, not `run-function`. A hand-installed `age` is the
fallback only when no CommonsSec_Age checkout is available at all.
