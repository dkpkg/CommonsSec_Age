-- CommonsSec_Age.Age -- materialize age + its YubiKey/passkey plugins for a slot.
--
-- Usage (after the package has been distributed once; see AUTHORING.md):
--   ./dk0 -I etc/dk/v --trust-local-package CommonsSec_Age \
--     run-function CommonsSec_Age.Age.Files@1.3.1 -d target/age slot=Release.Windows_x86_64
--   ./dk0 -I etc/dk/v --trust-local-package CommonsSec_Age \
--     run CommonsSec_Age.Age.Age@1.3.1 'args[]=--version'
--
-- Ported from CommonsLang_DotNet/etc/dk/v/CommonsLang_DotNet/SDK.values.lua. It
-- bundles three upstreams (age, age-plugin-yubikey, age-plugin-fido2-hmac) into
-- one slot directory. Supported slots = the intersection all three ship.
--
-- Validation status: the three bundles are validated (dk0 get-bundle downloaded
-- the real archives and verified these checksums). The rule below is NOT yet
-- exercised: a brand-new local rule only becomes runnable after the first
-- `distribute` build (which needs prepare-version); a bare `run-function` cannot
-- build it. See AUTHORING.md. lua-ml has no local functions, so a should-be-
-- unique global table holds the helpers.
--
-- The F_Untar version tracks the imported CommonsBase_Std's Extract module
-- (0.3.0 for CommonsBase_Std 2.6.x). Update it if `dk0 add`/`update` pulls a
-- CommonsBase_Std whose Extract.F_Untar has a different version.

CommonsSec_Age_Age = {
  id_module = "CommonsSec_Age.Age",
  id_version = "1.3.1",           -- headline = the age version
  age_bundle = "CommonsSec_Age.Age.Bundle@1.3.1",
  yubikey_bundle = "CommonsSec_Age.AgePluginYubikey.Bundle@0.5.1",
  fido2_bundle = "CommonsSec_Age.AgePluginFido2Hmac.Bundle@0.5.0"
}

local M = {
  id = CommonsSec_Age_Age.id_module .. "@" .. CommonsSec_Age_Age.id_version
}
rules, uirules = build.newrules(M)

function CommonsSec_Age_Age.form_output_id()
  return string.format("%s.Form@%s",
    CommonsSec_Age_Age.id_module,
    CommonsSec_Age_Age.id_version)
end

function CommonsSec_Age_Age.supported_slots()
  -- Intersection of what age (1.3.1), age-plugin-yubikey (0.5.1, no Linux), and
  -- age-plugin-fido2-hmac (0.5.0) all publish as release binaries.
  return {
    "Release.Windows_x86_64",
    "Release.Darwin_x86_64",
    "Release.Darwin_arm64"
  }
end

-- Per-slot declared output files (must match the real archive contents).
CommonsSec_Age_Age.paths = {}
-- Windows extracts each whole .zip, so every extracted file must be declared
-- here. The Unix side instead selects `unix_paths` through F_Untar, which is why
-- these two extra age binaries appear only in the Windows list.
CommonsSec_Age_Age.paths.Windows_x86_64 = {
  "age/age.exe",
  "age/age-keygen.exe",
  "age/age-inspect.exe",
  "age/age-plugin-batchpass.exe",
  "age/LICENSE",
  "age-plugin-yubikey/age-plugin-yubikey.exe",
  "age-plugin-fido2-hmac/age-plugin-fido2-hmac.exe",
  "age-plugin-fido2-hmac/LICENSE"
}
CommonsSec_Age_Age.paths.Darwin = {
  "age/age",
  "age/age-keygen",
  "age/LICENSE",
  "age-plugin-yubikey/age-plugin-yubikey",
  "age-plugin-fido2-hmac/age-plugin-fido2-hmac",
  "age-plugin-fido2-hmac/LICENSE"
}
-- Per-tool subsets, used to drive the selective Unix F_Untar extraction.
CommonsSec_Age_Age.unix_paths = {}
CommonsSec_Age_Age.unix_paths.age = { "age/age", "age/age-keygen", "age/LICENSE" }
CommonsSec_Age_Age.unix_paths.yubikey = { "age-plugin-yubikey/age-plugin-yubikey" }
CommonsSec_Age_Age.unix_paths.fido2 = {
  "age-plugin-fido2-hmac/age-plugin-fido2-hmac",
  "age-plugin-fido2-hmac/LICENSE"
}

-- Per-tool archive filename for a slot.
function CommonsSec_Age_Age.asset_for(tool, slot)
  if tool == "age" then
    if slot == "Release.Windows_x86_64" then return "age-v1.3.1-windows-amd64.zip" end
    if slot == "Release.Darwin_x86_64" then return "age-v1.3.1-darwin-amd64.tar.gz" end
    if slot == "Release.Darwin_arm64" then return "age-v1.3.1-darwin-arm64.tar.gz" end
  elseif tool == "yubikey" then
    if slot == "Release.Windows_x86_64" then return "age-plugin-yubikey-v0.5.1-x86_64-windows.zip" end
    if slot == "Release.Darwin_x86_64" then return "age-plugin-yubikey-v0.5.1-x86_64-darwin.tar.gz" end
    if slot == "Release.Darwin_arm64" then return "age-plugin-yubikey-v0.5.1-arm64-darwin.tar.gz" end
  elseif tool == "fido2" then
    if slot == "Release.Windows_x86_64" then return "age-plugin-fido2-hmac-v0.5.0-windows-amd64.zip" end
    if slot == "Release.Darwin_x86_64" then return "age-plugin-fido2-hmac-v0.5.0-darwin-amd64.tar.gz" end
    if slot == "Release.Darwin_arm64" then return "age-plugin-fido2-hmac-v0.5.0-darwin-arm64.tar.gz" end
  end
  error("Unsupported tool/slot: " .. tool .. "/" .. slot)
end

function CommonsSec_Age_Age.paths_arr(paths)
  local pathsarr = {}
  local key, value = 1, paths[1]
  while value do
    pathsarr[key] = "paths[]=" .. value
    key, value = key + 1, paths[key + 1]
  end
  return table.concat(pathsarr, " ")
end

-- Windows: get-asset natively extracts each tool's .zip. Each command gets its
-- OWN -d, because two commands may not share one output path; `-n 1` strips the
-- archive's leading directory so the final layout is still the single slot dir
-- of `paths.Windows_x86_64` (age/..., age-plugin-yubikey/..., etc.).
function CommonsSec_Age_Age.form_values_windows(slot)
  local private = {}
  private[1] = string.format("get-asset %s -p %s -n 1 -d ${SLOT.%s}/age",
    CommonsSec_Age_Age.age_bundle, CommonsSec_Age_Age.asset_for("age", slot), slot)
  private[2] = string.format("get-asset %s -p %s -n 1 -d ${SLOT.%s}/age-plugin-yubikey",
    CommonsSec_Age_Age.yubikey_bundle, CommonsSec_Age_Age.asset_for("yubikey", slot), slot)
  private[3] = string.format("get-asset %s -p %s -n 1 -d ${SLOT.%s}/age-plugin-fido2-hmac",
    CommonsSec_Age_Age.fido2_bundle, CommonsSec_Age_Age.asset_for("fido2", slot), slot)
  local outputs = {
    assets = { { slots = { slot }, paths = CommonsSec_Age_Age.paths.Windows_x86_64 } }
  }
  return { private = private }, outputs
end

-- Unix (Darwin): one selective F_Untar per tool. Each command gets its OWN -d,
-- because two commands may not share one output path, and `nstrip=1` drops the
-- archive's leading directory so the final layout is still the single slot dir
-- of `paths.Darwin`. This mirrors the `-n 1` the Windows branch passes.
function CommonsSec_Age_Age.form_values_unix(slot)
  local private = {}
  private[1] = string.format(
    "run-function CommonsBase_Std.Extract.F_Untar@0.3.0 -d ${SLOT.%s}/age nstrip=1 modver=CommonsSec_Age.Age.Unix.Age.%s@1.3.1 tarmodver=%s tarassetpath=%s %s",
    slot, slot, CommonsSec_Age_Age.age_bundle, CommonsSec_Age_Age.asset_for("age", slot),
    CommonsSec_Age_Age.paths_arr(CommonsSec_Age_Age.unix_paths.age))
  private[2] = string.format(
    "run-function CommonsBase_Std.Extract.F_Untar@0.3.0 -d ${SLOT.%s}/age-plugin-yubikey nstrip=1 modver=CommonsSec_Age.Age.Unix.Yubikey.%s@0.5.1 tarmodver=%s tarassetpath=%s %s",
    slot, slot, CommonsSec_Age_Age.yubikey_bundle, CommonsSec_Age_Age.asset_for("yubikey", slot),
    CommonsSec_Age_Age.paths_arr(CommonsSec_Age_Age.unix_paths.yubikey))
  private[3] = string.format(
    "run-function CommonsBase_Std.Extract.F_Untar@0.3.0 -d ${SLOT.%s}/age-plugin-fido2-hmac nstrip=1 modver=CommonsSec_Age.Age.Unix.Fido2.%s@0.5.0 tarmodver=%s tarassetpath=%s %s",
    slot, slot, CommonsSec_Age_Age.fido2_bundle, CommonsSec_Age_Age.asset_for("fido2", slot),
    CommonsSec_Age_Age.paths_arr(CommonsSec_Age_Age.unix_paths.fido2))
  local outputs = {
    assets = { { slots = { slot }, paths = CommonsSec_Age_Age.paths.Darwin } }
  }
  return { private = private }, outputs
end

-- `run-rule CommonsSec_Age.Age.Files@1.3.1 -d <dir> slot=<slot>` materializes the
-- age + plugin binaries into <dir> for the given slot. This is the surface the
-- dkpkg signing driver points its -AgeExe / PATH at.
function rules.Files(command, request)
  if command == "declareoutput" then
    local slot = assert(request.user.slot, "please provide `slot=SLOT`")
    return {
      declareoutput = {
        return_objects = {
          id = CommonsSec_Age_Age.form_output_id(),
          slots = CommonsSec_Age_Age.supported_slots(),
          execution_slot = slot
        }
      }
    }
  elseif command == "submit" then
    local slot = assert(request.user.slot, "please provide `slot=SLOT`")
    local is_windows = string.find(slot, "Windows_") ~= nil
    local precommands, outputs = nil, nil
    if is_windows then
      precommands, outputs = CommonsSec_Age_Age.form_values_windows(slot)
    else
      precommands, outputs = CommonsSec_Age_Age.form_values_unix(slot)
    end
    return {
      submit = {
        values = {
          schema_version = { major = 1, minor = 0 },
          forms = {
            {
              id = request.submit.outputid,
              precommands = precommands,
              outputs = outputs
            }
          }
        }
      }
    }
  end
end

-- Scrub inherited age configuration so a run is hermetic.
function CommonsSec_Age_Age.envmods()
  return {
    "-AGE",
    "-AGE_PLUGIN",
    "-AGE_PLUGIN_BINARY"
  }
end

function CommonsSec_Age_Age.common_submit_response(request)
  local slot = "Release." .. assert(request.execution.ABIv3, "Expected `request.execution.ABIv3`")
  local outputid = CommonsSec_Age_Age.form_output_id()
  local is_windows = string.find(slot, "Windows_") ~= nil
  local precommands, outputs = nil, nil
  if is_windows then
    precommands, outputs = CommonsSec_Age_Age.form_values_windows(slot)
  else
    precommands, outputs = CommonsSec_Age_Age.form_values_unix(slot)
  end
  return {
    submit = {
      values = {
        schema_version = { major = 1, minor = 0 },
        forms = {
          { id = outputid, precommands = precommands, outputs = outputs }
        }
      },
      expressions = {
        directories = {
          agedir = "$(get-object " .. outputid .. " -s " .. slot .. " -d :)"
        },
        files = {},
        strings = { extexe = "${.exe.execution}" }
      }
    }
  }
end

-- `dk0 run CommonsSec_Age.Age.Age@1.3.1 'args[]=--version'` runs `age <args>`.
-- NOTE: plugin discovery (for age1yubikey1.../fido2 recipients) needs the plugin
-- subdirs on PATH; the dkpkg signing driver wires that. Validate with dk0 before
-- relying on plugin-using operations here.
function uirules.Age(command, request, continue_)
  if command == "submit" then
    return CommonsSec_Age_Age.common_submit_response(request)
  elseif command == "ui" then
    local agedir = request.io.realpath(assert(request.continued.agedir,
      "Expected `agedir` defined in `expressions.directories`"))
    local program = agedir .. "/age/age" .. request.continued.extexe
    local userargs = request.arg or {}
    local args = {}
    local n = table.getn(userargs) ---@diagnostic disable-line: deprecated, access-invisible
    table.move(userargs, 1, n, 1, args)
    assert(request.ui.spawn {
      program = program,
      envmods = CommonsSec_Age_Age.envmods(),
      args = args
    })
  end
end

return M
