#!/usr/bin/env bash
# ZStats T7 script installer. Use explicit roots for Proton or custom clients.
set -euo pipefail

usage() {
    echo 'Usage: install.sh [--to BO3_DIR] [--appdata-root DIR] [--compiler-root DIR] [--state-root DIR] [--route auto|boiii|appdata|t7x|compiler|all] [--install|--find|--verify|--uninstall|--configure] [--yes]'
}

game=''
appdata=''
compiler=''
state_root=''
route='auto'
action='install'
yes=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --to|--appdata-root|--compiler-root|--state-root|--route)
            option="$1"
            shift
            [ "$#" -gt 0 ] || { usage; exit 2; }
            case "$option" in
                --to) game="$1" ;;
                --appdata-root) appdata="$1" ;;
                --compiler-root) compiler="$1" ;;
                --state-root) state_root="$1" ;;
                --route) route="$1" ;;
            esac ;;
        --find) action='find' ;;
        --install) action='install' ;;
        --verify) action='verify' ;;
        --uninstall) action='uninstall' ;;
        --configure) action='configure' ;;
        --yes) yes=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
    shift
done
case "$route" in auto|boiii|appdata|t7x|compiler|all) ;; *) usage; exit 2 ;; esac

# Git Bash accepts Windows drive paths but sha256sum escapes their backslashes
# with a leading marker. Normalize explicit roots before hashing or copying.
normalize_root() {
    if command -v cygpath >/dev/null 2>&1 && [[ "$1" =~ ^[A-Za-z]:[\\/] ]]; then
        cygpath -u "$1"
    else
        printf '%s' "$1"
    fi
}
[ -z "$game" ] || game="$(normalize_root "$game")"
[ -z "$appdata" ] || appdata="$(normalize_root "$appdata")"
[ -z "$compiler" ] || compiler="$(normalize_root "$compiler")"
[ -z "$state_root" ] || state_root="$(normalize_root "$state_root")"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
payload="$script_dir"
for _ in 1 2 3 4; do
    [ -f "$payload/zstats.release" ] && break
    payload="$(dirname "$payload")"
done
[ -f "$payload/zstats.release" ] || { echo 'Extract the complete ZStats T7 script ZIP.'; exit 1; }

if [ "$action" = configure ]; then
    echo 'BOIII and T7x: open ZSTATS SETTINGS in the Zombies lobby or pause menu.'
    echo 't7-compiler injection has no ui_scripts menu; use the zs_* console dvars.'
    echo 'Career PB storage needs the Lua settings menu and is unavailable on compiler-only installs.'
    exit 0
fi

steam_roots=("$HOME/.steam/steam" "$HOME/.steam/root" "$HOME/.local/share/Steam"
             "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
             "$HOME/.var/app/com.valvesoftware.Steam/data/Steam")
for mount in /run/media/mmcblk0p1 /run/media/deck/* /run/media/*; do
    [ -d "$mount/steamapps" ] && steam_roots+=("$mount")
done
libraries=()
for steam in "${steam_roots[@]}"; do
    [ -d "$steam/steamapps" ] || continue
    libraries+=("$steam")
    vdf="$steam/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
        while IFS= read -r library; do [ -d "$library/steamapps" ] && libraries+=("$library"); done \
            < <(grep -oE '"path"[[:space:]]+"[^"]+"' "$vdf" 2>/dev/null |
                sed -E 's/.*"path"[[:space:]]+"([^"]+)".*/\1/')
    fi
done
if [ -z "$game" ]; then
    for library in "${libraries[@]}"; do
        root="$library/steamapps/common"
        [ -d "$root" ] || continue
        for candidate in "$root"/*Black\ Ops\ III*; do
            [ -d "$candidate" ] || continue
            if [ -f "$candidate/BlackOps3.exe" ] || [ -f "$candidate/boiii.exe" ] || [ -f "$candidate/t7x.exe" ]; then
                game="$candidate"
                break
            fi
        done
        [ -n "$game" ] && break
    done
fi
if [ -n "$game" ] && [ ! -d "$game" ]; then echo "Game folder not found: $game"; exit 1; fi
if [ -n "$compiler" ] && [ ! -d "$compiler" ]; then echo "Compiler folder not found: $compiler"; exit 1; fi
if [ -z "$appdata" ] && [ -n "${LOCALAPPDATA:-}" ]; then appdata="$(normalize_root "$LOCALAPPDATA")"; fi
if [ -z "$appdata" ]; then
    for library in "${libraries[@]}"; do
        for candidate in "$library/steamapps/compatdata/311210/pfx/drive_c/users"/*/AppData/Local; do
            if [ -d "$candidate/boiii/data" ]; then appdata="$candidate"; break 2; fi
        done
    done
fi

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
    else shasum -a 256 "$1" | awk '{print $1}'; fi
}
owned() {
    [ -f "$1" ] && [ -f "$1.zstats.sha256" ] && [ "$(hash_file "$1")" = "$(tr -d '\r\n' < "$1.zstats.sha256")" ]
}
log_action() {
    printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$log_file"
}
prepare_log() {
    local state="${state_root:-${XDG_STATE_HOME:-$HOME/.local/state}/zstats}"
    mkdir -p "$state"
    log_file="$state/install.log"
    log_action "plan $route"
}
confirm() {
    [ "$yes" -eq 1 ] && return 0
    printf '%s [y/N] ' "$1"
    read -r answer || return 1
    case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

source_dirs=()
target_dirs=()
route_names=()
add_route() {
    local key="$1" source="$2" target="$3"
    [ -d "$payload/$source" ] || { echo "Missing payload route: $payload/$source"; exit 1; }
    source_dirs+=("$payload/$source")
    target_dirs+=("$target")
    route_names+=("$key")
}
if [ "$route" = boiii ] || [ "$route" = all ] || { [ "$route" = auto ] && [ -n "$game" ] && { [ -d "$game/boiii" ] || [ -f "$game/boiii.exe" ]; }; }; then
    if [ -n "$game" ] && { [ -d "$game/boiii" ] || [ -f "$game/boiii.exe" ]; }; then
        add_route boiii 'Black Ops III/boiii' "$game/boiii"
    elif [ "$route" = boiii ] && [ "$action" != find ]; then echo 'BOIII client marker not found in game folder.'; exit 1; fi
fi
if [ "$route" = appdata ] || [ "$route" = all ]; then
    if [ -n "$appdata" ] && [ -d "$appdata/boiii/data" ]; then
        add_route appdata 'AppData/boiii/data' "$appdata/boiii/data"
    elif [ "$route" = appdata ] && [ "$action" != find ]; then
        echo 'Original BOIII AppData folder not found; Ezz BOIII prunes this route on launch.'; exit 1
    fi
fi
if [ "$route" = t7x ] || [ "$route" = all ] || { [ "$route" = auto ] && [ -n "$game" ] && { [ -d "$game/t7x" ] || [ -f "$game/t7x.exe" ]; }; }; then
    if [ -n "$game" ] && { [ -d "$game/t7x" ] || [ -f "$game/t7x.exe" ]; }; then
        add_route t7x t7x "$game/t7x"
    elif [ "$route" = t7x ] && [ "$action" != find ]; then echo 'T7x client marker not found in game folder.'; exit 1; fi
fi
if [ "$route" = compiler ] || [ "$route" = all ]; then
    if [ -n "$compiler" ]; then add_route compiler t7-compiler "$compiler"
    elif [ "$route" = compiler ] && [ "$action" != find ]; then
        echo 'Compiler project folder not supplied.'; exit 1
    fi
fi
if [ "${#source_dirs[@]}" -eq 0 ]; then
    echo 'No selected route found. Pass --to, --appdata-root, or --compiler-root.'
    [ "$action" = find ] && exit 0
    exit 1
fi

files=()
targets=()
ready=()
shared=()
for i in "${!source_dirs[@]}"; do
    source="${source_dirs[$i]}"
    target="${target_dirs[$i]}"
    while IFS= read -r -d '' file; do
        relative="${file#"$source"/}"
        files+=("$file")
        targets+=("${target:+$target/$relative}")
        if [ "${route_names[$i]}" = compiler ] && { [ "$relative" = gsc.conf ] || [ "$relative" = README.md ]; }; then
            shared+=(1)
        else
            shared+=(0)
        fi
        if [ -n "$target" ]; then ready+=(1)
        else ready+=(0); fi
    done < <(find "$source" -type f -print0)
done

count=0
bad=0
for i in "${!files[@]}"; do
    target="${targets[$i]}"
    if [ "${ready[$i]}" -ne 1 ]; then state='not found'
    elif [ ! -f "$target" ]; then state='absent'
    elif [ "$(hash_file "${files[$i]}")" = "$(hash_file "$target")" ]; then state='current'
    else state='different'; fi
    echo "$state - $target"
    if [ "${ready[$i]}" -eq 1 ]; then count=$((count+1)); [ "$state" = current ] || bad=$((bad+1)); fi
done
[ "$action" = find ] && exit 0
[ "$count" -gt 0 ] || { echo 'No selected client route is installed.'; exit 1; }
if [ "$action" = verify ]; then
    [ "$bad" -eq 0 ] || { echo "$bad script file(s) absent or different."; exit 1; }
    echo "Verified $count ZStats script file(s)."
    exit 0
fi
if [ "$action" = uninstall ]; then
    confirm "Remove $count ZStats script file(s)?" || exit 0
    prepare_log
    for i in "${!files[@]}"; do
        [ "${ready[$i]}" -eq 1 ] || continue
        [ "${shared[$i]}" -eq 0 ] || continue
        target="${targets[$i]}"
        if ! owned "$target"; then echo "Modified or unowned file left alone: $target"; continue; fi
        rm -- "$target"
        if [ -f "$target.zstats-backup" ]; then mv -- "$target.zstats-backup" "$target"; fi
        rm -- "$target.zstats.sha256"
        log_action "removed $target"
    done
    exit 0
fi
confirm "Install $count ZStats script file(s)?" || exit 0
prepare_log
for i in "${!files[@]}"; do
    [ "${ready[$i]}" -eq 1 ] || continue
    target="${targets[$i]}"
    if [ "${shared[$i]}" -eq 1 ]; then
        if [ -f "$target" ] && [ "$(hash_file "$target")" != "$(hash_file "${files[$i]}")" ]; then
            echo "Shared compiler infrastructure differs; merge refused: $target" >&2
            exit 1
        fi
        continue
    fi
    if [ -f "$target" ] && ! owned "$target" && [ -f "$target.zstats-backup" ]; then
        echo "Cannot replace changed file while its backup already exists: $target" >&2
        exit 1
    fi
done
for i in "${!files[@]}"; do
    [ "${ready[$i]}" -eq 1 ] || continue
    target="${targets[$i]}"
    mkdir -p "$(dirname "$target")"
    if [ "${shared[$i]}" -eq 1 ]; then
        if [ ! -f "$target" ]; then
            cp -- "${files[$i]}" "$target"
            log_action "installed shared compiler infrastructure $target"
        fi
        continue
    fi
    if [ -f "$target" ] && ! owned "$target" && [ ! -f "$target.zstats-backup" ]; then
        cp -- "$target" "$target.zstats-backup"
    fi
    cp -- "${files[$i]}" "$target"
    hash_file "$target" > "$target.zstats.sha256"
    log_action "installed $target"
done
echo "Installed $count ZStats T7 script file(s). Start a new Zombies match."
