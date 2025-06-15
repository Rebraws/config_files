#!/bin/bash



readonly SERVER_ALIAS="gpuserver"
readonly LOCAL_SETUP_SCRIPT="~/Programming/server-script.sh"
readonly LOCAL_PUBLIC_KEY=$(cat ~/.ssh/id_gpu.pub)

readonly REMOTE_SETUP_SCRIPT="/workspace/setup_server.sh"
readonly REMOTE_INFO_FILE="/workspace/.keys/server_info.txt"

readonly LOCAL_INFO_DIR="$HOME/.config/server_tokens"
readonly LOCAL_INFO_FILE="${LOCAL_INFO_DIR}/server_info.txt"

readonly SSH_CONFIG_FILE="$HOME/.ssh/config"

info() {
    echo "ℹ️  $1"
}

success() {
    echo "✅ $1"
}

error() {
    echo "❌ ERROR: $1" >&2
    exit 1
}


main() {
    info "Retrieving instance details from vast.ai..."
    local vast_output
    vast_output=$(vast show instances | tail -n 1)

    if [[ -z "$vast_output" ]]; then
        error "Could not retrieve instance information from vast.ai. Is an instance running?"
    fi

    local instance_id ssh_addr ssh_port
    read -r instance_id _ _ _ _ _ _ _ _ ssh_addr ssh_port _ <<<"$vast_output"

    if [[ -z "$ssh_addr" || -z "$ssh_port" ]]; then
        error "Could not parse SSH address or port from vast.ai output:\n$vast_output"
    fi

    info "Updating SSH config for '$SERVER_ALIAS'..."
    sed -i.bak \
        -e "/^Host ${SERVER_ALIAS}$/,/^\s*$/ s/^\(\s*HostName\s*\).*$/\1${ssh_addr}/" \
        -e "/^Host ${SERVER_ALIAS}$/,/^\s*$/ s/^\(\s*Port\s*\).*$/\1${ssh_port}/" \
        "$SSH_CONFIG_FILE"

    success "SSH config updated for ${SERVER_ALIAS}:"
    echo "  HostName: $ssh_addr"
    echo "  Port: $ssh_port"

    info "Adding SSH key to server instance ${instance_id}..."
    vast attach ssh "${instance_id}" "${LOCAL_PUBLIC_KEY}"

    info "🚀 Starting connection and setup process for ${SERVER_ALIAS}..."

    info "Running setup script on the server..."
    scp ~/Programming/server-script.sh ${SERVER_ALIAS}:/workspace/setup_server.sh
    ssh  ${SERVER_ALIAS} 'chmod +x /workspace/setup_server.sh'
    ssh  ${SERVER_ALIAS} 'bash /workspace/setup_server.sh'

    info "Downloading connection info from server..."
    mkdir -p "$LOCAL_INFO_DIR"
    scp "${SERVER_ALIAS}:${REMOTE_INFO_FILE}" "${LOCAL_INFO_FILE}"

    if [[ ! -f "$LOCAL_INFO_FILE" ]]; then
        error "Could not download server_info.txt from the server."
    fi

    info "Sourcing server keys securely..."
    while IFS='=' read -r key value; do
        value="${value%\"}"
        value="${value#\"}"
        case "$key" in
            DISTANT_TOKEN)
                export DISTANT_TOKEN="$value"
                ;;
            MOSH_KEY)
                export MOSH_KEY="$value"
                ;;
        esac
    done < "$LOCAL_INFO_FILE"

    if [[ -z "${DISTANT_TOKEN:-}" ]]; then
        error "DISTANT_TOKEN not found in ${LOCAL_INFO_FILE}."
    fi
    
    success "Distant token is ready for Neovim."
    echo "  Distant Token: ${DISTANT_TOKEN:0:8}..." # Show only a preview

    info "Starting Distant manager in the background..."
    nohup distant manager listen --user &

    echo "🎉 All done!"
}

main "$@"
