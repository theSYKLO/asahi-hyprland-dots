#! /bin/sh
set -e

echo "🛠️  Starting setup script..."

echo "📥 Checking and adding Cloudflare Warp repo if missing..."
[ -f /etc/yum.repos.d/cloudflare-warp.repo ] || \
curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo

echo "📦 Installing RPM Fusion free & nonfree repos..."
sudo dnf -y install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "⚙️  Enabling fedora-cisco-openh264 codec..."
sudo dnf -y config-manager setopt fedora-cisco-openh264.enabled=1

echo "🔑 Importing Microsoft GPG key..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

echo "📥 Checking and adding VSCode repo if missing..."
[ -f /etc/yum.repos.d/vscode.repo ] || \
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | \
sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

echo "♻️  Refreshing package metadata cache..."
sudo dnf makecache --refresh

echo "📦 Installing essential packages..."
sudo dnf -y install code warp-cli gcc g++ make cmake git gh vim nvim btop fastfetch flatpak snapd dbus-devel pkgconf-pkg-config --skip-unavailable 2>&1 | tee dnf-install.log 
grep -i 'Skipping unavailable package' dnf-install.log > skipped-dnf-packages.log || true

if [ -s skipped-dnf-packages.log ]; then
  echo "⚠️  Some packages were skipped:"
  cat skipped-dnf-packages.log
else
  echo "✅ All packages installed successfully."
fi

echo "📥 Adding Flathub remote if missing..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "📦 Installing Telegram via Snap..."
sudo snap install telegram-asahi

echo "📦 Installing Galaxy Buds Client via Flatpak..."
flatpak install -y --noninteractive flathub me.timschneeberger.GalaxyBudsClient

echo "🚀 Enabling Hyprland COPR repo..."
sudo dnf copr enable lionheartp/Hyprland -y

echo "📦 Installing Hyprland and related packages..."
sudo dnf install -y hyprland nm-applet dunst qt6ct warp-taskbar wl-clipboard waybar-git kitty aquamarine hyprgraphics hypridle hyprlang hyprlock hyprland-qt-support hyprland-qtutils hyprpaper hyprpicker hyprcursor hyprpolkitagent hyprshot hyprsunset hyprsysteminfo hyprutils xdg-desktop-portal-hyprland --skip-unavailable --best  2>&1 | tee hypr-install.log
grep -i 'Skipping unavailable package' hypr-install.log > skipped-hypr-packages.log || true

if [ -s skipped-hypr-packages.log ]; then
  echo "⚠️  Some packages were skipped:"
  cat skipped-hypr-packages.log
else
  echo "✅ All packages installed successfully."
fi

echo "📁 Setting up needed directory and copying dotfiles..."
if [ -d "$HOME/.local/bin" ]; then
  cp ./dotfiles/custom-bins/code "$HOME/.local/bin/"
else
  mkdir -p "$HOME/.local/bin"
  cp ./dotfiles/custom-bins/code "$HOME/.local/bin/"
fi

if [ -d "$HOME/.config" ]; then
  cp -r ./dotfiles/hypr ./dotfiles/waybar ./dotfiles/wofi "$HOME/.config/"
else
  mkdir -p "$HOME/.config"
  cp -r ./dotfiles/hypr ./dotfiles/waybar ./dotfiles/wofi "$HOME/.config/"
fi

echo "📦 Downloading and installing clipse..."
mkdir -p clipse
cd clipse
wget -c https://github.com/savedra1/clipse/releases/download/v1.1.0/clipse_1.1.0_linux_arm64.tar.gz -O - | tar -xz
sudo mv clipse /usr/local/bin
cd ..

echo "🦀 Checking Rust and Cargo installation..."
command -v cargo >/dev/null || sudo dnf -y install rust cargo

echo "📥 Cloning and building bluetui..."
[ -d bluetui ] || git clone https://github.com/pythops/bluetui
cd bluetui
cargo build --release
sudo mv target/release/bluetui /usr/local/bin
cd ..

echo "♻️  Updating all packages and refreshing metadata..."
sudo dnf update -y

echo "✅ Installation complete."

read -p "Would you like to reboot now? (y/N): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
  echo "🔄 Rebooting system..."
  reboot
else
  echo "💡 Reboot skipped. Remember to reboot later if needed."
fi
