#!/bin/bash

# Log file
LOG_FILE="install_log.txt"

# Function to check and install missing packages
install_if_missing() {
  package=$1
  if ! dpkg -l | grep -qw $package; then
    echo "Installing $package..." | tee -a $LOG_FILE
    sudo apt-get install -y $package | tee -a $LOG_FILE
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
  "build-essential"
  "make"
  "git"
  "libcurl4-openssl-dev"
  "libz-dev"
  "libglew-dev"
  "libsdl2-dev"
  "python3"
)

# Update package list and install necessary packages
sudo apt-get update | tee -a $LOG_FILE
for package in "${packages[@]}"; do
  install_if_missing $package
done

# Define repository directory
REPO_DIR="sm64ex-coop"

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
git clone https://github.com/djoslin0/sm64ex-coop
cd "$REPO_DIR" || { echo "Failed to enter the $REPO_DIR directory. Aborting."; exit 1; }

# Notify checking out specific commit
echo "Checking out specific commit dd278f0..." | tee -a $LOG_FILE
git checkout dd278f0

# Check for the presence of "baserom.us.z64"
if [ ! -f "baserom.us.z64" ]; then
  echo "baserom.us.z64 not found." | tee -a $LOG_FILE
  echo "Drag and drop the baserom.us.z64 file onto this terminal or paste the file path:"
  read -r baserom_path

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

# Notify build process
echo "Building the project with $num_jobs jobs..." | tee -a $LOG_FILE
make -j"$num_jobs" 2>&1 | tee -a $LOG_FILE

# Notify completion
echo "Finished building sm64ex-coop." | tee -a $LOG_FILE

# Remove log file upon completion
rm -f $LOG_FILE
