# CommonsSec_Age

A dk package that redistributes the [age](https://github.com/FiloSottile/age)
file-encryption tool and its hardware-token plugins
([age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey),
[age-plugin-fido2-hmac](https://github.com/olastor/age-plugin-fido2-hmac)) as
per-ABI prebuilt binaries.

It exists to give the dkpkg **signing** flow pinned, reproducible age tooling: the
maintainer's `prepare-dkpkg-version.ps1` encrypts each package's signing transcript
to YubiKey/passkey recovery recipients (see `dksdk-coder/plans/signing/`). That
driver materializes `age` from this package on demand with `dk0 get-asset` (which
auto-extracts the pinned Windows binaries and works from a local checkout even
before release -- validated), so no separate `age` install is needed. A
hand-installed `age` is the fallback only when no CommonsSec_Age checkout is
available.

Status: **authored, pending dk0 validation + release.** The three bundles carry
real, GitHub-API-verified SHA-256/size pins (age 1.3.1, age-plugin-yubikey 0.5.1,
age-plugin-fido2-hmac 0.5.0), the `Age.values.lua` rules and the CI workflow are
written. What remains is dk0-generated / hardware-gated: the workspace import
(`dk0 add`), the `dist/any.u` object value-ids (dk0 build), and
`etc/dk/d/0.1.0.dist.json` (prepare-version). See [AUTHORING.md](AUTHORING.md).

Supported ABIs = **Windows_x86_64, Darwin_x86_64, Darwin_arm64** — the
intersection of what all three tools ship. There is **no Linux build**:
age-plugin-yubikey 0.5.1 publishes no Linux release binary.

## Layout (target, mirroring CommonsLang_DotNet)

```text
dk.u                       # manifest: Overview, License, workspace import of CommonsBase_Std, Apparatus assets
dk0, dk0.cmd               # launchers (copied from dksdk-coder/ext/dk)
etc/dk/d/0.1.0.dist.json   # produced by prepare-dkpkg-version (hardware-gated)
etc/dk/i/*.values.json     # pinned CommonsBase_Std import records
etc/dk/v/CommonsSec_Age/
  Age.Bundle.values.jsonc              # per-ABI FiloSottile/age release archives
  AgePluginYubikey.Bundle.values.jsonc # per-ABI str4d/age-plugin-yubikey archives
  AgePluginFido2Hmac.Bundle.values.jsonc # per-ABI olastor/age-plugin-fido2-hmac archives
  Age.values.lua                       # supported_slots() + rules.Files + runner uirules
dist/any.u                 # distribution script (dk0-generated value-ids)
.github/workflows/distribute-0.1.yml   # tag 0.1.*, environment dk-distribution, ABI matrix
```

## Consuming

```sh
dk0 add github-l2 dkpkg/CommonsSec_Age
```
