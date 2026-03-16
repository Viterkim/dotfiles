#!/usr/bin/env bash
set -euo pipefail

CLIPCOPY_BIN="$HOME/dotfiles/own_bin_helpers/clipcopy.sh"

json_or_text () { # cmd...
  if outstr="$("$@" 2>/dev/null)"; then
    printf "%s" "$outstr"
  else
    printf "null"
  fi
}

[ -x "$CLIPCOPY_BIN" ] || {
  echo "Clipboard helper not found or not executable: $CLIPCOPY_BIN" >&2
  exit 1
}

CLIP="$("$CLIPCOPY_BIN" --backend)"

# --- Collect ---
HOSTNAME="$(hostname 2>/dev/null || echo unknown)"
OS_RELEASE_RAW="$(cat /etc/os-release 2>/dev/null || true)"
KERNEL_RAW="$(uname -a 2>/dev/null || true)"

# tool versions
VER_INXI="$(inxi -V 2>/dev/null || true)"
VER_LSHW="$(lshw -version 2>/dev/null | head -n1 || true)"
VER_NVME="$(nvme version 2>/dev/null || true)"
VER_SMARTCTL="$(smartctl -V 2>/dev/null | head -n1 || true)"
VER_BOLT="$(boltctl --version 2>/dev/null || true)"
VER_SENSORS="$(sensors -v 2>/dev/null | head -n1 || true)"
VER_PCIIDS="$(lspci -vmm >/dev/null 2>&1 && echo "pciutils present" || true)"

# JSON-capable or text outputs (always captured as raw strings)
INXI_RAW="$(json_or_text inxi -Fazy --output json)"
LSHW_RAW="$(json_or_text sudo lshw -json)"
LSCPU_RAW="$(json_or_text lscpu -J)"
LSBLK_RAW="$(json_or_text lsblk -J -o NAME,KNAME,PKNAME,TYPE,SIZE,FSTYPE,FSVER,MOUNTPOINT,MODEL,SERIAL,UUID,PARTUUID,ROTA,RM,RO)"
BLKID_RAW="$(json_or_text sudo blkid)"
NVME_LIST_RAW="$(json_or_text sudo nvme list -o json)"
NVME_SMART_RAW="$(json_or_text sudo nvme smart-log /dev/nvme0 -o json)"
SMARTCTL_RAW="$(json_or_text sudo smartctl -j -a /dev/nvme0)"
SENSORS_RAW="$(json_or_text sensors -j)"
RFKILL_RAW="$(json_or_text rfkill list)"
IW_RAW="$(json_or_text iw dev)"
IP_ADDR_RAW="$(json_or_text ip -j -br a)"
LSPCI_RAW="$(json_or_text lspci -nnk)"
LSUSB_RAW="$(json_or_text lsusb)"
LSUSB_TREE_RAW="$(json_or_text lsusb -t)"
BOLT_RAW="$(json_or_text boltctl -o json list)"
AUDIO_PACTL_RAW="$(json_or_text pactl list short sinks)"
AUDIO_APLAY_RAW="$(json_or_text aplay -l)"
DRM_DEV_RAW="$(json_or_text bash -lc "ls -l /sys/class/drm/ | sed -n '1,200p'")"
XRANDR_RAW="$(json_or_text xrandr --current)"
DMESG_TAIL_RAW="$(json_or_text bash -lc $'dmesg | grep -E -i "thermal|throttle|tsc|cpufreq|nvme|amdgpu|i915|radeon|wifi|wlan|ath|iwl|realtek|bluetooth" | tail -n 500')"

POWER_STATE_RAW="$(json_or_text cat /sys/power/state)"
MEM_SLEEP_RAW="$(json_or_text cat /sys/power/mem_sleep)"
ASPM_RAW="$(json_or_text cat /sys/module/pcie_aspm/parameters/policy)"

# batteries -> build a tiny JSON ourselves (jq <=1.5-safe)
BAT_ARRAY="[]"
for b in /sys/class/power_supply/BAT*; do
  [ -d "$b" ] || continue
  j="$(jq -n \
    --arg name "$(basename "$b")" \
    --arg status "$(cat "$b/status" 2>/dev/null || true)" \
    --arg capacity "$(cat "$b/capacity" 2>/dev/null || true)" \
    --arg cycle_count "$(cat "$b/cycle_count" 2>/dev/null || true)" \
    --arg voltage_now "$(cat "$b/voltage_now" 2>/dev/null || true)" \
    --arg current_now "$(cat "$b/current_now" 2>/dev/null || true)" \
    --arg charge_full "$(cat "$b/charge_full" 2>/dev/null || true)" \
    --arg charge_full_design "$(cat "$b/charge_full_design" 2>/dev/null || true)" \
    --arg energy_full "$(cat "$b/energy_full" 2>/dev/null || true)" \
    --arg energy_full_design "$(cat "$b/energy_full_design" 2>/dev/null || true)" \
    '{
      name: $name,
      status: (if ($status|length)>0 then $status else null end),
      capacity_percent: (if ($capacity|length)>0 then $capacity else null end),
      cycle_count: (if ($cycle_count|length)>0 then $cycle_count else null end),
      voltage_now_uV: (if ($voltage_now|length)>0 then $voltage_now else null end),
      current_now_uA: (if ($current_now|length)>0 then $current_now else null end),
      charge_full_uAh: (if ($charge_full|length)>0 then $charge_full else null end),
      charge_full_design_uAh: (if ($charge_full_design|length)>0 then $charge_full_design else null end),
      energy_full_uWh: (if ($energy_full|length)>0 then $energy_full else null end),
      energy_full_design_uWh: (if ($energy_full_design|length)>0 then $energy_full_design else null end)
    }')"
  BAT_ARRAY="$(jq -cn --argjson arr "$BAT_ARRAY" --argjson item "$j" '$arr + [$item]')"
done

CRYPT_STATUS_RAW="$(json_or_text bash -lc "cryptsetup status --verbose /dev/mapper/* 2>/dev/null")"

# Build JSON, parsing strings where possible
jq -n \
  --arg schema_version "1.0.3" \
  --arg generated_at "$(date --iso-8601=seconds)" \
  --arg hostname "$HOSTNAME" \
  --arg os_release "$OS_RELEASE_RAW" \
  --arg kernel "$KERNEL_RAW" \
  --arg ver_inxi "$VER_INXI" \
  --arg ver_lshw "$VER_LSHW" \
  --arg ver_nvme "$VER_NVME" \
  --arg ver_smartctl "$VER_SMARTCTL" \
  --arg ver_bolt "$VER_BOLT" \
  --arg ver_sensors "$VER_SENSORS" \
  --arg ver_pciids "$VER_PCIIDS" \
  --arg inxi "$INXI_RAW" \
  --arg lshw "$LSHW_RAW" \
  --arg lscpu "$LSCPU_RAW" \
  --arg lsblk "$LSBLK_RAW" \
  --arg blkid "$BLKID_RAW" \
  --arg nvme_list "$NVME_LIST_RAW" \
  --arg nvme_smart "$NVME_SMART_RAW" \
  --arg smartctl "$SMARTCTL_RAW" \
  --arg sensors "$SENSORS_RAW" \
  --arg rfkill "$RFKILL_RAW" \
  --arg iw "$IW_RAW" \
  --arg ip_addr "$IP_ADDR_RAW" \
  --arg lspci "$LSPCI_RAW" \
  --arg lsusb "$LSUSB_RAW" \
  --arg lsusb_tree "$LSUSB_TREE_RAW" \
  --arg bolt "$BOLT_RAW" \
  --arg audio_pactl "$AUDIO_PACTL_RAW" \
  --arg audio_aplay "$AUDIO_APLAY_RAW" \
  --arg drm_devices "$DRM_DEV_RAW" \
  --arg xrandr "$XRANDR_RAW" \
  --arg dmesg_tail "$DMESG_TAIL_RAW" \
  --arg power_state "$POWER_STATE_RAW" \
  --arg mem_sleep "$MEM_SLEEP_RAW" \
  --arg aspm_policy "$ASPM_RAW" \
  --arg crypt_status "$CRYPT_STATUS_RAW" \
  --arg batteries_json "$BAT_ARRAY" \
  '
  def maybe_fromjson: try fromjson catch .;
  def parse_lines_to_kv:
    (split("\n") | map(select(length>0)))
    | map( split("=") | {(.[0]): ( (.[1] // "") | gsub("^\"|\"$";"") )} ) | add;

  {
    schema_version: $schema_version,
    meta: {
      generated_at: $generated_at,
      hostname: $hostname,
      tools: {
        inxi: $ver_inxi,
        lshw: $ver_lshw,
        nvme: $ver_nvme,
        smartctl: $ver_smartctl,
        boltctl: $ver_bolt,
        sensors: $ver_sensors,
        pciutils: $ver_pciids
      }
    },
    system: {
      os: ( if ($os_release|length)>0 then ($os_release | parse_lines_to_kv) else {} end ),
      kernel: $kernel
    },
    inventory: {
      inxi: ($inxi | maybe_fromjson),
      lshw: ($lshw | maybe_fromjson),
      cpu: ($lscpu | maybe_fromjson),
      pci: $lspci,
      usb: { lsusb: $lsusb, tree: $lsusb_tree, thunderbolt: ($bolt | maybe_fromjson) },
      storage: {
        lsblk: ($lsblk | maybe_fromjson),
        blkid: $blkid,
        cryptsetup_status: $crypt_status,
        nvme_list: ($nvme_list | maybe_fromjson),
        nvme_smart: ($nvme_smart | maybe_fromjson),
        smartctl: ($smartctl | maybe_fromjson)
      },
      power: {
        power_state: $power_state,
        mem_sleep: $mem_sleep,
        pcie_aspm_policy: $aspm_policy,
        batteries: ($batteries_json | fromjson),
        sensors: ($sensors | maybe_fromjson)
      },
      graphics: { drm_devices: $drm_devices, xrandr: $xrandr },
      audio: { pactl_sinks: $audio_pactl, aplay_cards: $audio_aplay },
      network: { ip_brief: ($ip_addr | maybe_fromjson), rfkill: $rfkill, iw: $iw },
      logs: { dmesg_tail: $dmesg_tail }
    }
  }' | "$CLIPCOPY_BIN"

echo "Copied hardware report JSON to clipboard via $CLIP" >&2
