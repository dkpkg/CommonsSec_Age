# Authoring checklist — CommonsSec_Age

This repo is a **scaffold**. The remaining files carry dk0-generated
content-addressed value-ids and real per-ABI SHA-256 checksums, so they must be
produced with dk0 + real release downloads — not hand-written. Template package:
`Y:\source\CommonsLang_DotNet` (a prebuilt-runtime bundle with a single
`CommonsBase_Std` dependency). Model: `dksdk-coder/plans/signing/` and the
`dk-ai:make-dk-package-from-autoconf` / dk0-authoring references.

## Upstreams to pin (author-time)

Resolve the latest stable release of each and record, per ABI, the archive URL +
SHA-256 + size:

- **age** — github.com/FiloSottile/age releases (per-OS `.tar.gz` / `.zip`).
- **age-plugin-yubikey** — github.com/str4d/age-plugin-yubikey releases.
- **age-plugin-fido2-hmac** — github.com/olastor/age-plugin-fido2-hmac releases.

`supported_slots()` = the **intersection** of ABIs all three ship. At minimum
`Release.Windows_x86_64` (the maintainer host). Drop any ABI a plugin does not
provide rather than faking it (record the drop, per the no-silent-caps rule).

## Steps

1. **Launchers**: copy `dk0` + `dk0.cmd` from `dksdk-coder/ext/dk` (or a sibling
   dkpkg package). Copy the `.gitattributes`/`.gitignore` already here.
2. **Workspace**: `dk0 add github-l2 dkpkg/CommonsBase_Std` then `dk0 update` to
   fill `dk.u`'s `## workspace` block and `etc/dk/i/*.values.json`. Do not
   hand-write hashes.
3. **Bundles**: author `etc/dk/v/CommonsSec_Age/{Age,AgePluginYubikey,AgePluginFido2Hmac}.Bundle.values.jsonc`
   mirroring `CommonsLang_DotNet/etc/dk/v/CommonsLang_DotNet/SDK.Bundle.values.jsonc`
   — `bundles[].id`, `listing.origins[].mirrors` = the release download base, and
   `assets[]` = per-ABI `{path, checksum.sha256, size, origin}` from the pinned
   releases.
4. **Rules**: author `etc/dk/v/CommonsSec_Age/Age.values.lua` mirroring
   `SDK.values.lua`: `supported_slots()`, per-slot file lists, a `rules.Files`
   extractor (Windows `get-asset` the zip; Unix `run-function
   CommonsBase_Std.Extract.F_Untar` the tarball; chmod +x the binaries in a
   continuation), and `uirules.Age` / `uirules.AgePluginYubikey` /
   `uirules.AgePluginFido2Hmac` runner rules with a scrubbed env.
5. **Distribution**: author `dist/any.u` (mirror `CommonsLang_DotNet/dist/any.u`);
   its `\dk.object(...)` value-ids are produced by dk0 during a build, not by
   hand.
6. **CI**: copy `.github/workflows/distribute-0.1.yml` from CommonsLang_DotNet;
   keep the `dk-distribution` environment, the `distribute_0_1_pubkey/_seckey`
   secrets, the ABI matrix, and the combine→attest→release job. Add a Windows
   `short-build-dir: C:\b` only if MAX_PATH bites.
7. **Local validation (first pass)**: `dk0 get-bundle
   CommonsSec_Age.Age.Bundle@<ver>`, `dk0 run-rule CommonsSec_Age.Age.Files -d
   target/age slot=Release.Windows_x86_64`, then run the extracted `age --version`
   and `age-plugin-yubikey --version`.
8. **prepare-version (hardware-gated)**: after provisioning the recovery YubiKeys
   (`dksdk-coder/skills/manage-signing-recipients/SKILL.md`), run
   `dksdk-coder/scripts/prepare-dkpkg-version.ps1 -Package CommonsSec_Age -Spdx
   BSD-3-Clause` **with a hand-installed age** (bootstrap: this package is the
   source of the pinned age, so its own first prepare-version cannot use it).
9. **Release + CI validation**: tag `0.1.0`; validate via
   `dksdk-coder:github-actions-validation`.

## Bootstrap note

CommonsSec_Age is the source of the pinned age tooling, so a chicken-and-egg
exists: its own first `prepare-version` (and any package prepared before it ships)
must use a hand-installed `age` + plugins. Once `CommonsSec_Age@0.1.0` is released,
`prepare-dkpkg-version.ps1` should prefer the pinned dk bundle.
