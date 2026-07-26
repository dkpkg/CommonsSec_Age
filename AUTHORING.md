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
3. **Validate the module (first pass)** — this is where `Age.values.lua` gets
   proven; expect to adjust it:
   - `dk0 -I etc/dk/v --trust-local-package CommonsSec_Age get-bundle
     CommonsSec_Age.Age.Bundle@1.3.1 -d target/agebundle` (repeat for the two
     plugin bundles);
   - `dk0 -I etc/dk/v --trust-local-package CommonsSec_Age run-rule
     CommonsSec_Age.Age.Files@1.3.1 -d target/age slot=Release.Windows_x86_64`,
     then run `target/age/age/age.exe --version`.
   - Note: the Darwin binaries extract without +x (reproducible-zip limitation);
     if `run`/consumers need them executable, add a chmod continuation to
     `rules.Files` as `SDK.values.lua`'s `workaround_make_dotnet_executable` does.
     The Windows host (the only slot the signing flow strictly needs) is unaffected.
4. **Distribution value-ids**: let dk0 record the `\dk.object(...)` lines in
   `dist/any.u` during the build.
5. **prepare-version (hardware-gated)**: after provisioning the recovery YubiKeys
   (`dksdk-coder/skills/manage-signing-recipients/SKILL.md`), run
   `dksdk-coder/scripts/prepare-dkpkg-version.ps1 -Package CommonsSec_Age -Spdx
   BSD-3-Clause` **with a hand-installed age** (bootstrap: this package is the
   source of the pinned age, so its own first prepare-version cannot use it).
6. **Release + CI validation**: tag `0.1.0`; validate via
   `dksdk-coder:github-actions-validation`.

## Refresh (later versions)

Re-pin by re-running `gh api repos/<owner>/<repo>/releases/latest --jq
'.assets[] | {name, size, digest}'` for each tool, updating the three bundle
files' versions/paths/checksums and `Age.values.lua`'s `asset_for` + versions.

## Bootstrap note

CommonsSec_Age is the source of the pinned age tooling, so a chicken-and-egg
exists: its own first `prepare-version` (and any package prepared before it ships)
must use a hand-installed `age` + plugins. Once `CommonsSec_Age@0.1.0` is released,
`prepare-dkpkg-version.ps1` should prefer the pinned dk bundle.
