#!/system/bin/sh
MODDIR=${0%/*}
CONFIG_DIR=/data/adb/tricky_store

echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  Clear Persistent Key Storage"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " "
echo "  This deletes all cached attestation keys."
echo "  Apps using attestation will re-enroll on next use."
echo " "
echo "  🔊  Vol+  = Confirm clear"
echo "  🔉  Vol-  = Cancel (default after 10s)"
echo " "

confirm() {
    vol_tmp="${TMPDIR:-/data/local/tmp}/teesim_vol_key"
    seconds=10

    : > "$vol_tmp"
    getevent -qlc 1 > "$vol_tmp" 2>/dev/null &
    ge_pid=$!

    while [ "$seconds" -gt 0 ]; do
        sleep 1
        if ! kill -0 "$ge_pid" 2>/dev/null; then
            key=$(awk '/KEY_/{print $3}' "$vol_tmp" 2>/dev/null)
            case "$key" in
                KEY_VOLUMEUP)
                    rm -f "$vol_tmp"
                    return 0
                    ;;
                KEY_VOLUMEDOWN)
                    rm -f "$vol_tmp"
                    return 1
                    ;;
            esac
            : > "$vol_tmp"
            getevent -qlc 1 > "$vol_tmp" 2>/dev/null &
            ge_pid=$!
        fi
        seconds=$((seconds - 1))
    done

    kill "$ge_pid" 2>/dev/null
    wait "$ge_pid" 2>/dev/null
    rm -f "$vol_tmp"
    return 1
}

if ! confirm; then
    echo " "
    echo "  ❌ Cancelled — keys preserved"
    exit 0
fi

if [ -d "$CONFIG_DIR/persistent_keys" ]; then
    rm -rf "$CONFIG_DIR/persistent_keys"
    mkdir -p "$CONFIG_DIR/persistent_keys"
    echo " "
    echo "  ✅ Persistent key storage cleared"
else
    echo " "
    echo "  ℹ️  No persistent key storage found"
fi
