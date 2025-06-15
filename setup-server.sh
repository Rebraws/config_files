#!/bin/bash

# Server Setup Script - Enhanced Version
# Sets up development environment with mosh, distant, and neovim

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
export DEBIAN_FRONTEND=noninteractive
readonly WORKSPACE_DIR="/workspace"
readonly KEY_DIR="${WORKSPACE_DIR}/.keys"
readonly KEY_FILE="${KEY_DIR}/server_info.txt"
readonly CONFIG_REPO="https://github.com/rebraws/config_files"
readonly DISTANT_HOST="127.0.0.1"
readonly DISTANT_PORT="8181"
readonly MOSH_PORT="60001"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code"
        log_info "Cleaning up background processes..."
        pkill -f "mosh-server" 2>/dev/null || true
        pkill -f "distant" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to kill existing processes
kill_existing_processes() {
    log_info "Stopping existing processes..."
    
    if pgrep -f "distant" >/dev/null 2>&1; then
        pkill -f "distant" && log_info "Stopped existing distant processes"
    fi
    
    if pgrep -f "mosh-server" >/dev/null 2>&1; then
        pkill -f "mosh-server" && log_info "Stopped existing mosh-server processes"
    fi
    
    # Wait a moment for processes to terminate
    sleep 2
}

# Function to install packages
install_packages() {
    local packages=("mosh" "neovim" "clang" "clang-tools" "clangd")
    local missing_packages=()
    
    log_info "Checking for required packages..."
    
    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "All required packages are already installed"
        return 0
    fi
    
    log_info "Missing packages: ${missing_packages[*]}"
    log_info "Updating package list..."
    
    if ! sudo apt-get update; then
        log_error "Failed to update package list"
        return 1
    fi
    
    log_info "Installing missing packages..."
    if ! sudo apt-get install -y "${missing_packages[@]}"; then
        log_error "Failed to install packages"
        return 1
    fi
    
    log_success "Successfully installed all required packages"
}

# Function to install distant
install_distant() {
    log_info "Checking for Distant installation..."
    
    # Ensure distant path is in PATH for checking
    export PATH="$HOME/.local/bin:$PATH"
    
    if command_exists distant; then
        local distant_version
        distant_version=$(distant --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "Distant is already installed: $distant_version"
        return 0
    fi
    
    log_info "Installing Distant..."
    
    if ! curl -fsSL https://sh.distant.dev | sh -s -- --on-conflict overwrite --run-as-admin; then
        log_error "Failed to install Distant"
        return 1
    fi
    
    # Ensure distant is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command_exists distant; then
        log_error "Distant installation failed - command not found"
        return 1
    fi
    
    log_success "Distant installed successfully"
}

# Function to setup mosh server
setup_mosh() {
    log_info "Setting up Mosh server on port $MOSH_PORT..."
    
    # Start mosh-server and capture output (like original script)
    local mosh_output
    mosh_output=$(mosh-server new -p "$MOSH_PORT" -i 0.0.0.0 2>&1)
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to start mosh-server"
        echo "$mosh_output"
        return 1
    fi
    
    # Extract mosh connection info using same method as original
    MOSH_PORT_ACTUAL=$(echo "$mosh_output" | grep 'MOSH CONNECT' | awk '{print $3}')
    MOSH_KEY=$(echo "$mosh_output" | grep 'MOSH CONNECT' | awk '{print $4}')
    
    if [[ -z "$MOSH_KEY" || -z "$MOSH_PORT_ACTUAL" ]]; then
        log_error "Failed to extract mosh connection information from output:"
        echo "$mosh_output"
        return 1
    fi
    
    log_success "Mosh server started on port $MOSH_PORT_ACTUAL"
}

# Function to setup distant server
setup_distant() {
    log_info "Setting up Distant server on $DISTANT_HOST:$DISTANT_PORT..."
    
    # Start distant server and capture output (like original script)
    local distant_output
    distant_output=$("$HOME/.local/bin/distant" server listen --daemon --host "$DISTANT_HOST" --port "$DISTANT_PORT" 2>&1)
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to start distant server"
        echo "$distant_output"
        return 1
    fi
    
    # Extract distant token using same method as original
    DISTANT_TOKEN=$(echo "$distant_output" | grep 'distant://' | awk -F: '{print $3}' | awk -F@ '{print $1}')
    
    if [[ -z "$DISTANT_TOKEN" ]]; then
        log_error "Failed to extract distant token from output:"
        echo "$distant_output"
        return 1
    fi
    
    log_success "Distant server started with token"
}

# Function to save server information
save_server_info() {
    log_info "Saving server information to $KEY_FILE..."
    
    mkdir -p "$KEY_DIR"
    
    cat > "$KEY_FILE" << EOF
# Server connection information
# Generated on $(date)

MOSH_KEY=${MOSH_KEY}
MOSH_PORT=${MOSH_PORT_ACTUAL}
DISTANT_TOKEN=${DISTANT_TOKEN}
DISTANT_HOST=${DISTANT_HOST}
DISTANT_PORT=${DISTANT_PORT}

# Usage examples:
# mosh --ssh="ssh -p 22" user@host --port=\$MOSH_PORT --key=\$MOSH_KEY
# distant client connect distant://\$DISTANT_TOKEN@\$DISTANT_HOST:\$DISTANT_PORT
EOF
    
    chmod 600 "$KEY_FILE"  # Secure the file
    log_success "Server information saved to $KEY_FILE"
}

# Function to setup neovim configuration
setup_neovim() {
    log_info "Setting up Neovim configuration..."
    
    local config_dir="$HOME/.config/nvim"
    local temp_repo_dir
    temp_repo_dir=$(mktemp -d)
    
    # Clone configuration repository
    if ! git clone "$CONFIG_REPO" "$temp_repo_dir"; then
        log_warning "Failed to clone config repository. Skipping nvim setup."
        rm -rf "$temp_repo_dir"
        return 0
    fi
    
    # Create nvim config directory
    mkdir -p "$config_dir"
    
    # Copy configuration file
    if [[ -f "$temp_repo_dir/init.vim" ]]; then
        cp "$temp_repo_dir/init.vim" "$config_dir/init.vim"
        log_success "Neovim configuration installed"
    else
        log_warning "init.vim not found in config repository"
    fi
    
    # Cleanup
    rm -rf "$temp_repo_dir"
}

# Function to display connection information
display_connection_info() {
    echo
    log_success "=== SERVER SETUP COMPLETE ==="
    echo
    echo "Connection Information:"
    echo "  Mosh Port: $MOSH_PORT_ACTUAL"
    echo "  Mosh Key:  $MOSH_KEY"
    echo "  Distant:   distant://$DISTANT_TOKEN@$DISTANT_HOST:$DISTANT_PORT"
    echo
}

setup_python_env() {
    local python_dir="${WORKSPACE_DIR}/Programming"
    local venv_dir="${python_dir}/python-env"
    
    log_info "Setting up Python virtual environment..."
    
    # Create Programming directory if it doesn't exist
    if [[ ! -d "$python_dir" ]]; then
        log_info "Creating Programming directory at $python_dir"
        mkdir -p "$python_dir"
    else
        log_info "Programming directory already exists"
    fi
    
    # Check if python3 is available
    if ! command_exists python3; then
        log_error "python3 is not installed. Please install Python 3 first."
        return 1
    fi
    
    # Create virtual environment if it doesn't exist
    if [[ ! -d "$venv_dir" ]]; then
        log_info "Creating Python virtual environment at $venv_dir"
        if ! python3 -m venv "$venv_dir"; then
            log_error "Failed to create Python virtual environment"
            return 1
        fi
        log_success "Python virtual environment created successfully"
    else
        log_info "Python virtual environment already exists at $venv_dir"
    fi
    
}

# Main execution
main() {
    log_info "Starting server setup..."
    
    kill_existing_processes
    install_packages
    install_distant
    setup_mosh
    setup_distant
    save_server_info
    setup_neovim
    display_connection_info
    setup_python_env

    log_success "Server setup completed successfully!"
    exit
}

# Run main function
main "$@"
