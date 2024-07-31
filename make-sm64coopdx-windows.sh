#!/bin/bash

# Log file
LOG_FILE="install_log.txt"

# Function to check and install missing packages
install_if_missing() {
  package=$1
  if ! pacman -Qi $package &>/dev/null; then
    echo "Installing $package..." | tee -a $LOG_FILE
    pacman -S --noconfirm $package | tee -a $LOG_FILE
  else
    echo "$package is already installed." | tee -a $LOG_FILE
  fi
}

# Redirect all output to the log file
exec > >(tee -a $LOG_FILE) 2>&1

# Notify start of package installation
echo "Starting package installation..." | tee -a $LOG_FILE

# List of necessary packages
packages=(
  "unzip"
  "make"
  "git"
  "mingw-w64-i686-gcc"
  "mingw-w64-x86_64-gcc"
  "mingw-w64-i686-glew"
  "mingw-w64-x86_64-glew"
  "mingw-w64-i686-SDL2"
  "mingw-w64-i686-SDL"
  "mingw-w64-x86_64-SDL2"
  "mingw-w64-x86_64-SDL"
  "python3"
)

# Install necessary packages
for package in "${packages[@]}"; do
  install_if_missing $package
done

# Define repository directory
REPO_DIR="sm64coopdx"

# Check if the repository directory exists
if [ -d "$REPO_DIR" ]; then
  echo "Repository directory $REPO_DIR already exists." | tee -a $LOG_FILE
  echo "Do you want to delete it and re-clone? (y/n):" | tee -a $LOG_FILE
  read -r response
  case "$response" in
    [Yy])
      echo "Deleting existing repository directory..." | tee -a $LOG_FILE
      rm -rf "$REPO_DIR" | tee -a $LOG_FILE
      ;;
    [Nn])
      echo "Keeping existing repository directory." | tee -a $LOG_FILE
      ;;
    *)
      echo "Invalid response. Aborting." | tee -a $LOG_FILE
      exit 1
      ;;
  esac
fi

# Notify repository cloning
echo "Cloning the repository..." | tee -a $LOG_FILE
git clone https://github.com/coop-deluxe/sm64coopdx
cd "$REPO_DIR" || { echo "Failed to enter the $REPO_DIR directory. Aborting."; exit 1; }

# Check for the presence of "baserom.us.z64"
if [ ! -f "baserom.us.z64" ]; then
  echo "baserom.us.z64 not found." | tee -a $LOG_FILE
  echo "Drag and drop the baserom.us.z64 file onto this terminal or paste the file path:"
  read -r baserom_path

  # Handle path if dropped directly into terminal
  baserom_path=$(echo "$baserom_path" | sed 's/^.*\(\.\)\(\/\)\(.*\)$/\1\/\3/')

  # Check if user provided a path
  if [ -z "$baserom_path" ]; then
    echo "Error: No path provided. Aborting." | tee -a $LOG_FILE
    exit 1
  fi

  # Check if file exists
  if [ ! -f "$baserom_path" ]; then
    echo "Error: File not found at $baserom_path. Aborting." | tee -a $LOG_FILE
    exit 1
  fi

  # Copy the baserom file to the repository directory
  echo "Copying baserom.us.z64 to repository directory..." | tee -a $LOG_FILE
  cp "$baserom_path" ./baserom.us.z64
  echo "File copied successfully." | tee -a $LOG_FILE
fi

# Prompt for the number of jobs
echo "Enter the number of jobs to use for 'make' (default is 4):"
read -r num_jobs

# Use default value if no input is provided
num_jobs=${num_jobs:-4}

# Prompt for the rendering API
echo "Select the rendering API (D3D11 or GL, default is GL):"
read -r render_api

# Use default value if no input is provided
render_api=${render_api:-GL}

# Notify build process
echo "Building the project with $num_jobs jobs and $render_api rendering API..." | tee -a $LOG_FILE
make -j"$num_jobs" RENDER_API="$render_api" 2>&1 | tee -a $LOG_FILE

# Notify completion
echo "Finished building sm64coopdx." | tee -a $LOG_FILE

# Remove log file upon completion
rm -f $LOG_FILE