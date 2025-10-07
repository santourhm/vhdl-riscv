#!/bin/bash
set -e

GHDL_CMD="ghdl"
WORK_LIB_NAME="work"
WORK_DIR_NAME="ghdl_work" # Directory for GHDL's compiled files

VHDL_STD_FLAG="--std=08"
SYNOPSYS_FLAG="-fsynopsys"
GHDL_ANALYSIS_FLAGS="$VHDL_STD_FLAG $SYNOPSYS_FLAG --work=$WORK_LIB_NAME --workdir=$WORK_DIR_NAME"
# GHDL_ELABORATE_FLAGS: Not used in this analysis-only script version, but keep for later
OTHER_GHDL_FLAGS="-frelaxed-rules" # For stdio_h.vhdl shared variable errors

# --- Configuration: Choose which RISCV_CONFIG to use ---
# Option 1: Use the one in tools/ (if you moved/renamed your main config there)
CHOSEN_CONFIG_FILE="tools/riscv_config.vhd"       # <<<< ADJUST THIS PATH TO YOUR MAIN CONFIG FILE
CONFIG_TO_EXCLUDE="riscv/riscv_config_20k.vhd"  # <<<< ADJUST THIS PATH

# Option 2: Use the 20k one
# CHOSEN_CONFIG_FILE="riscv/riscv_config_20k.vhd"
# CONFIG_TO_EXCLUDE="tools/riscv_config.vhd" # Or "riscv/rom/riscv_config.vhd" if that was the other

if [ -z "$CHOSEN_CONFIG_FILE" ] || [ ! -f "$CHOSEN_CONFIG_FILE" ]; then
    echo "ERROR: CHOSEN_CONFIG_FILE ('$CHOSEN_CONFIG_FILE') is not set or does not exist."
    exit 1
fi
if [ -z "$CONFIG_TO_EXCLUDE" ]; then # It's okay if CONFIG_TO_EXCLUDE doesn't exist, we just won't skip anything for it
    echo "INFO: No CONFIG_TO_EXCLUDE specified or it does not exist."
fi

# --- Stage 0: Essential Packages ---
# List absolute essentials here. Order within this list can matter.
ESSENTIAL_PACKAGES=(
    "tools/strings_h.vhdl"
"tools/regexp_h.vhdl"
"tools/ctype_h.vhdl"
"tools/stdlib_h.vhdl"
"tools/stdio_h.vhdl"
"tools/strings_h.vhdl"
"tools/debugio_h.vhdl"
"tools/endian_h.vhdl"
    #"$CHOSEN_CONFIG_FILE"       # Your primary configuration package
    "tools/riscv_types.vhd"     # <<<< ADJUST THIS PATH to your main types package file
    "tools/riscv_config.vhd"     # <<<< ADJUST THIS PATH to your main types package file
)

# --- Directories for subsequent stages ---
RISCV_CORE_DIR="riscv"
OTHER_SEARCH_DIRS=(
    "tools" # For any tools/ files not in ESSENTIAL_PACKAGES
    "IPs"
    "soc"
    "."     # Current directory for loose files like observer.vhd
)

# To keep track of compiled files and avoid recompiling
declare -A COMPILED_FILES_MAP

# --- Clean and Prepare ---
echo "INFO: Cleaning previous compilation artifacts from $WORK_DIR_NAME..."
rm -rf "$WORK_DIR_NAME"
echo "INFO: Re-creating work directory: $WORK_DIR_NAME"
mkdir -p "$WORK_DIR_NAME"
echo

# --- Helper function to compile a single file ---
compile_file() {
    local file_to_compile="$1"
    local file_description="$2"

    # Resolve to absolute path for consistent map key
    local abs_path_to_compile
    abs_path_to_compile=$(realpath "$file_to_compile")

    if [[ -n "${COMPILED_FILES_MAP[$abs_path_to_compile]}" ]]; then
        # echo "Skipping already compiled: $file_to_compile"
        return 0
    fi

    if [[ -f "$CONFIG_TO_EXCLUDE" && "$abs_path_to_compile" == "$(realpath "$CONFIG_TO_EXCLUDE")" ]]; then
        echo "Skipping (excluded config): $file_to_compile"
        COMPILED_FILES_MAP[$abs_path_to_compile]=1 # Mark as "processed"
        return 0
    fi

    echo "Compiling $file_description: $file_to_compile"
    $GHDL_CMD -a $GHDL_ANALYSIS_FLAGS $OTHER_GHDL_FLAGS "$file_to_compile"
    COMPILED_FILES_MAP[$abs_path_to_compile]=1
}

# --- Stage 0: Compile ESSENTIAL_PACKAGES ---
echo "INFO: Stage 0: Compiling ESSENTIAL package files..."
for file in "${ESSENTIAL_PACKAGES[@]}"; do
    if [ -f "$file" ]; then
        compile_file "$file" "Essential Package"
    else
        echo "WARNING: Essential package file NOT FOUND: $file. Please check path."
    fi
done
echo "INFO: Stage 0 finished."
echo

# --- Stage 1: Compile RISC-V Core Directory ($RISCV_CORE_DIR) ---
echo "INFO: Stage 1: Compiling VHDL files in '$RISCV_CORE_DIR' directory..."
# Compile _pkg.vhd files in RISCV_CORE_DIR first
if [ -d "$RISCV_CORE_DIR" ]; then
    find "$RISCV_CORE_DIR" -type f \( -name "*_pkg.vhd" -o -name "*.pkg.vhd" \) -print0 | while IFS= read -r -d $'\0' file; do
        compile_file "$file" "RISC-V Core Package"
    done
    # Then compile other .vhd/.vhdl files in RISCV_CORE_DIR
    find "$RISCV_CORE_DIR" -type f \( -name "*.vhd" -o -name "*.vhdl" \) \
                           ! -name "*_pkg.vhd" ! -name "*.pkg.vhd" \
                           -print0 | while IFS= read -r -d $'\0' file; do
        compile_file "$file" "RISC-V Core Entity/Arch"
    done
else
    echo "WARNING: RISC-V core directory '$RISCV_CORE_DIR' not found."
fi
echo "INFO: Stage 1 finished."
echo

# --- Stage 2: Compile files in OTHER_SEARCH_DIRS ---
echo "INFO: Stage 2: Compiling VHDL files in other directories (Tools (remaining), IPs, SOC, .)..."
# Compile _pkg.vhd files first
find "${OTHER_SEARCH_DIRS[@]}" -maxdepth 10 -type f \( -name "*_pkg.vhd" -o -name "*.pkg.vhd" \) -print0 | while IFS= read -r -d $'\0' file; do
    compile_file "$file" "Other Package"
done
# Then compile other .vhd/.vhdl files
find "${OTHER_SEARCH_DIRS[@]}" -maxdepth 10 -type f \( -name "*.vhd" -o -name "*.vhdl" \) \
                               ! -name "*_pkg.vhd" ! -name "*.pkg.vhd" \
                               -print0 | while IFS= read -r -d $'\0' file; do
    compile_file "$file" "Other Entity/Arch"
done
echo "INFO: Stage 2 finished."
echo

echo "INFO: VHDL compilation script finished."
echo "INFO: If all went well, your VHDL files should be analyzed into '$WORK_DIR_NAME'."