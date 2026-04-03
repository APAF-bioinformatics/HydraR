#!/bin/bash
set -euxo pipefail

echo "============================================="
echo " Starting Minimalist Jules Setup for HydraR  "
echo "============================================="

# 1. Update package list and fix any broken dpkg states from previous runs
sudo apt-get update
sudo apt-get --fix-broken install -y

# 2. Install ONLY the core tools, avoiding any system graphics library conflicts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsb-release \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    r-base-core

# 3. Setup Python venv for `reticulate`
python3 -m venv ~/.venv
echo 'export PATH="$HOME/.venv/bin:$PATH"' >> ~/.bashrc
echo "RETICULATE_PYTHON=\"$HOME/.venv/bin/python\"" >> ~/.Renviron

# 4. Extract OS codename (e.g., noble, jammy, bookworm)
OS_CODENAME=$(lsb_release -cs)

# 5. Bootstrap 'pak' (this zero-dependency binary bypasses the need for compilers)
sudo Rscript -e "install.packages('pak', repos = sprintf('https://r-lib.github.io/p/pak/stable/%s/%s/%s', .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"

# 6. Install all R and System Level Dependencies via pak
# We inject CI=true so it doesn't wait for interactive [Y/n] prompts
cd /app
sudo Rscript -e "\
  Sys.setenv(CI = 'true'); \
  options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/${OS_CODENAME}/latest')); \
  pak::local_install_deps('.', dependencies = TRUE)"
  
# 7. Install devtools
sudo Rscript -e "\
  Sys.setenv(CI = 'true'); \
  options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/${OS_CODENAME}/latest')); \
  pak::pkg_install('devtools')"

echo "============================================="
echo " Jules Environment successfully constructed! "
echo "============================================="
