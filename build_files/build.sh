#!/usr/bin/env bash

# "fail fast" / strict + debug combo
# -e : Exit immediately if any command in the script returns a non-zero status
# -u : Treat use of unset variables as an error and exit
# -x : Print each command (with arguments) as it is executed (good for logs)
# -o pipefail: Make a pipeline fail if any command in it fails, not just the last one
set -euxo pipefail

# Install binaries from latest GitHub release
gh_install_binary() {
    local repo="$1"
    
    local owner=$(jq -r ".${repo}.owner" /ctx/config.json)
    local arch=$(jq -r ".${repo}.arch[0]" /ctx/config.json)
    local strip_components=$(jq -r ".${repo}.strip_components" /ctx/config.json)
    local pattern=$(jq -r ".${repo}.pattern" /ctx/config.json)
    local pattern=${pattern//<<ARCH>>/$arch}
    local binary_name=$(jq -r ".${repo}.binary_name" /ctx/config.json)
    local binary_path=$(jq -r ".${repo}.binary_path" /ctx/config.json)
    
    # TODO: verify checksum
    
    local tmp_path="/tmp/${repo}.tar.gz"
    local opt_path="/opt/${repo}"
    local api_url="https://api.github.com/repos/${owner}/${repo}/releases/latest"
    local asset_url=$(
        curl -fsSL -H "Authorization: Bearer ${github_token}" \
        -H "Accept: application/vnd.github+json" "$api_url" \
        | jq -r --arg pat "$pattern" \
        '.assets[] | select(.name | test($pat)) | .browser_download_url' \
        | head -n1
    )
    
    if [[ -z "$asset_url" ]]; then
        echo "Could not find asset matching $pattern" >&2
        exit 1
    fi
    
    curl -Lso "$tmp_path" "$asset_url"

    mkdir "$opt_path"
    # avoid stripping too much ending up with empty folder
    if [[ "$strip_components" == "true" ]]; then
        tar -C "$opt_path" -xzf "$tmp_path" --strip-components=1
    else
        tar -C "$opt_path" -xzf "$tmp_path"
    fi

    ln -sf "${opt_path}/${binary_path}${binary_name}" "/usr/local/bin/${binary_name}"
    
}

github_token="$(cat /run/secrets/github_token)"

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git tar sudo jq

USER_UID=1000
USER_GID=$USER_UID
groupadd --gid $USER_GID $USERNAME
useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
mkdir -p /workspace
chown ${USERNAME}:${USER_GID} /workspace
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

gh_install_binary "zellij"
gh_install_binary "eza"
gh_install_binary "bat"
gh_install_binary "ripgrep"
gh_install_binary "neovim"

# TODO: Install fzf, fd, just, rclone, qpdf, jq, fish, atuin, tree-sitter
# TODO: Configure fish completions
# TODO: Create alias for eza to become ll
