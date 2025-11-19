#!/bin/zsh

# --- CONFIG ---
GOINFRE="/goinfre/$USER"
VAGRANT_HOME_DIR="$GOINFRE/vagrant_data"
VB_VM_DIR="$GOINFRE/vms"
ZSHRC="$HOME/.zshrc"

echo "===== Setting up Vagrant + VirtualBox in goinfre ====="
echo "User: $USER"
echo "Goinfre: $GOINFRE"
echo

# --- 1. Create goinfre folders safely ---
echo "[1/5] Creating folders..."
mkdir -p "$VAGRANT_HOME_DIR"
mkdir -p "$VB_VM_DIR"
echo "  - $VAGRANT_HOME_DIR"
echo "  - $VB_VM_DIR"

# --- 2. Configure VirtualBox to store VMs in goinfre ---
echo "[2/5] Configuring VirtualBox..."
VBoxManage setproperty machinefolder "$VB_VM_DIR"
echo "  ✓ VirtualBox machinefolder set to $VB_VM_DIR"

# --- 3. Install Vagrant alias into ~/.zshrc ---
echo "[3/5] Updating ~/.zshrc..."

# Remove any old alias
sed -i '/alias vagrant=/d' "$ZSHRC" 2>/dev/null

cat >> "$ZSHRC" <<EOF

alias vagrant='VAGRANT_HOME=$VAGRANT_HOME_DIR vagrant'
EOF

echo "  ✓ Alias added to ~/.zshrc"

# --- 4. Source zshrc so alias is active now ---
echo "[4/5] Reloading shell..."
source "$ZSHRC"

echo "[5/5] Done!"
echo
echo "========= SETUP COMPLETE ========="
echo "Vagrant boxes     → $VAGRANT_HOME_DIR"
echo "VirtualBox VMs    → $VB_VM_DIR"
echo
echo "You can now run: vagrant up"
echo "=================================="
