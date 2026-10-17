#!/bin/bash
# One-shot toolchain install for macOS (Apple Silicon). Re-runnable.
# Installs: yosys, icarus-verilog, z3 (via Homebrew); cocotb, click (pip);
#           SymbiYosys and MCY from source into /usr/local.
set -e

echo "== Homebrew packages"
brew list yosys >/dev/null 2>&1 || brew install yosys
brew list icarus-verilog >/dev/null 2>&1 || brew install icarus-verilog
brew list z3 >/dev/null 2>&1 || brew install z3

echo "== Python packages"
pip3 install --user cocotb click 2>/dev/null || pip3 install --break-system-packages cocotb click

SRC="$HOME/.local/src"
mkdir -p "$SRC"

echo "== SymbiYosys"
if ! command -v sby >/dev/null; then
  [ -d "$SRC/sby" ] || git clone --depth 1 https://github.com/YosysHQ/sby "$SRC/sby"
  (cd "$SRC/sby" && sudo make install)
fi

echo "== MCY"
if ! command -v mcy >/dev/null; then
  [ -d "$SRC/mcy" ] || git clone --depth 1 https://github.com/YosysHQ/mcy "$SRC/mcy"
  sudo mkdir -p /usr/local/bin /usr/local/share/mcy
  sudo install "$SRC/mcy/mcy.py" /usr/local/bin/mcy
  sudo cp -r "$SRC/mcy/scripts" /usr/local/share/mcy/
fi

echo
echo "== Versions"
yosys -V
iverilog -V | head -1
z3 --version
sby -h >/dev/null && echo "sby ok"
mcy --help >/dev/null && echo "mcy ok"
python3 -c "import cocotb, click; print('cocotb', cocotb.__version__)"
echo
echo "All good. Next: cd designs/fifo/tb && make"
