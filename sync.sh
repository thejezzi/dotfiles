#!/bin/bash
# Automatically change to the directory where this script is located
cd "$(dirname "$0")" || exit

echo "🔄 Synchronizing Dotfiles with Stow..."
# Run stow: --restow cleans up old links and creates new ones, --target=$HOME sets the destination
stow --restow --target="$HOME" .

echo "✅ Dotfiles successfully deployed to your home directory!"