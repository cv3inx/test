#!/usr/bin/env bash

# --- CONFIG ---
IMAGE="trakkdev/earnapp:latest"
BASE_DIR="$HOME/.EarnApp_Data"
LOG_FILE="EarnApp_Links.txt"

# --- COLORS ---
C="\033[0;36m" G="\033[0;32m" Y="\033[1;33m" R="\033[0;31m"
B="\033[1m" D="\033[2m" NC="\033[0m"

# --- UI HELPERS ---
line() { echo -e "${D}────────────────────────────────────────────${NC}"; }
msg()  { echo -e "${D}[${NC}${G}✓${NC}${D}]${NC} $1"; }
warn() { echo -e "${D}[${NC}${Y}!${NC}${D}]${NC} $1"; }
err()  { echo -e "${D}[${NC}${R}✗${NC}${D}]${NC} $1"; }
wait() { echo -ne "${D}[${NC}${C}wait${NC}${D}]${NC} $1\033[K\r"; }

# --- CLEANUP ---
cleanup() {
    echo -e "${Y}Removing all EarnApp containers...${NC}"
    docker rm -f $(docker ps -a --format '{{.Names}}' | grep "${1:-node}") &>/dev/null
    msg "Cleanup finished"
    exit 0
}

# --- DEPLOY NODE ---
deploy_container() {
    local index=$1
    local name="${PREFIX}-${index}"
    local data="${BASE_DIR}/${name}"

    if docker ps -a --format '{{.Names}}' | grep -Eq "^${name}$"; then
        warn "$name exists, skipping."
        return 1
    fi

    local uuid="sdk-node-$(head -c 512 /dev/urandom | md5sum | cut -d' ' -f1)"
    mkdir -p "$data"

    docker run -d \
        --name "$name" \
        --restart unless-stopped \
        --memory="256m" \
        --cpus="1" \
        --dns 1.1.1.1 --dns 8.8.8.8 \
        -e EARNAPP_UUID="$uuid" \
        -v "${data}:/etc/earnapp" \
        "$IMAGE" &>/dev/null

    if [[ $? -eq 0 ]]; then
        local link="https://earnapp.com/r/${uuid}"
        msg "${B}$name${NC} deployed"
        echo -e "   ${C}$link${NC}"
        echo "$name | $link" >> "$LOG_FILE"
        return 0
    else
        err "$name failed"
        return 1
    fi
}

# --- MAIN ---
main() {
    clear
    [[ "$1" == "delete" ]] && cleanup "$2"
    
    [[ $(sysctl -n net.ipv4.ip_forward) -eq 0 ]] && sysctl -w net.ipv4.ip_forward=1 &>/dev/null

    read -p "Enter container name ( Example: EarnApp): " PREFIX
    PREFIX=${PREFIX:-node}
    read -p "How many containers: " COUNT

    line
    msg "Pulling Image: $IMAGE"
    docker pull "$IMAGE" &>/dev/null
    line

    SUCCESS=0
    for i in $(seq 1 "$COUNT"); do
        deploy_container "$i"
        
        if [[ $? -eq 0 && $i -lt $COUNT ]]; then
            for s in {30..1}; do
                wait "Cooldown, please wait: ${s}s"
                sleep 1
            done
            echo -ne "\r\033[K"
        fi
    done
    
    line
    msg "Done! Links saved to $LOG_FILE"
}

main "$@"