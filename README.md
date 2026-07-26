# CommonsSec_Age

A dk package that redistributes the [age](https://github.com/FiloSottile/age)
file-encryption tool and its hardware-token plugins
([age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey),
[age-plugin-fido2-hmac](https://github.com/olastor/age-plugin-fido2-hmac)) as
per-ABI prebuilt binaries.

It exists to give the dkpkg **signing** flow pinned, reproducible age tooling: the
maintainer's `prepare-dkpkg-version.ps1` encrypts each package's signing transcript
to YubiKey/passkey recovery recipients (see `dksdk-coder/plans/signing/`). Until
this package ships, that flow uses a hand-installed `age`.

Status: **scaffold** — the bundle checksums, the `Age.values.lua` rules, the
distribution script, and the CI workflow are still to be authored/pinned. See
[AUTHORING.md](AUTHORING.md).

## Layout (target, mirroring CommonsLang_DotNet)

```
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

```
dk0 add github-l2 dkpkg/CommonsSec_Age
```
