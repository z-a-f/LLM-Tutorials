#!/bin/bash

# Creates all images that are stored under "tex", and stores them in "img"
#
# The "tex" folder must have "_template.tex" file, with "{{content}}" placeholder.
# Each latex file under "tex" (except "_template.tex") will be used to generate an image
# by adding its content to "_template.tex" and then running "pdflatex -shell-escape".
# The generated PNG is copied to the "img" folder.
#

USAGE=$(cat<<EOF
./tex2img.sh [--force] [--clean] [--buildpath <path>] [--texpath <path>] [--imgpath <path>]
    --force: Force rebuild all images. By default only builds images that don\'t exist
    --clean: Clean all images in the "img" folder
    -f, --file <file>: Path to a single specific tex file to build
    -b, --buildpath <path>: Path to the build folder / temporary folder. Default: "build"
    -t, --texpath <path>: Path to the tex folder. Default: "tex"
    -i, --imgpath <path>: Path to the img folder. Default: "img"
EOF
)
IFS=$'\n'
PARALLEL_JOBS=4

# Parse arguments
while [[ $# -gt 0 ]]; do
    # echo "$"
    case "${1}" in
        --force)
            FORCE=1
            shift
            ;;
        --clean)
            CLEAN=1
            shift
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        -b|--buildpath)
            BUILD_PATH="$2"
            shift 2
            ;;
        -t|--texpath)
            TEX_PATH="$2"
            shift 2
            ;;
        -i|--imgpath)
            IMG_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo -e "${USAGE}"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            echo -e "${USAGE}"
            exit 1
            ;;
    esac
done

export FORCE=${FORCE:-0}
export CLEAN=${CLEAN:-0}
export FILE=${FILE:-"*.tex"}
export BUILD_PATH=${BUILD_PATH:-"build"}
export TEX_PATH=$(realpath ${TEX_PATH:-"tex"})
export IMG_PATH=$(realpath ${IMG_PATH:-"img"})

# echo "===> DEBUG: FORCE=$FORCE, CLEAN=$CLEAN, BUILD_PATH=$BUILD_PATH, TEX_PATH=$TEX_PATH, IMG_PATH=$IMG_PATH"

# Check if in CLEAN mode
if [ $CLEAN -eq 1 ]; then
    echo "Cleaning $BUILD_PATH"
    rm -rf $BUILD_PATH/*
    exit 0
fi

# Make sure the "parallel" is installed
if ! command -v parallel &> /dev/null; then
    echo "The 'parallel' command is required but it's not installed. Aborting."
    exit 1
fi

# Make sure the "pdflatex" is installed
if ! command -v pdflatex &> /dev/null; then
    echo "The 'pdflatex' command is required but it's not installed. Aborting."
    exit 1
fi

# Make sure ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "The 'convert' command is required but it's not installed. Aborting."
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEX_PATH/_template.tex" ]; then
    echo "Template file not found: $TEX_PATH/_template.tex"
    exit 1
fi

# Collect all tex files
TEX_FILES=($(find "${TEX_PATH}" -type f -name "${FILE}" -not -name "_*.tex"))

# If not FORCE, exclude files that already have images
PNG_FILES=($(find "${IMG_PATH}" -type f -name "*.png"))
# echo Found "${#PNG_FILES[@]}" png files: "${PNG_FILES[@]}"
if [ $FORCE -eq 0 ]; then
    TEX_FILES=($(for f in "${TEX_FILES[@]}"; do
        fbase=$(basename "${f}")
        if [[ ! "${IFS}${PNG_FILES[*]}${IFS}" =~ "${IFS}${IMG_PATH}/${fbase%.*}.png${IFS}" ]]; then
            echo "${f}"
        fi
    done))
fi
echo Found "${#TEX_FILES[@]}" tex files: "${TEX_FILES[@]}"

# Check there are no tex files to process
if [ ${#TEX_FILES[@]} -eq 0 ]; then
    echo "No tex files to process. Exiting..."
    exit 0
fi

# Create build folder
mkdir -p "${BUILD_PATH}"
BUILD_PATH=$(realpath "${BUILD_PATH}")

# Copy the template into build files
for f in "${TEX_FILES[@]}"; do
    fbase=$(basename "${f}")
    cp ${TEX_PATH}/_template.tex "${BUILD_PATH}/${fbase}"
done

# Compile the tex files in the build directory in parallel
pdflatex_compile() {
    # echo "===> DEBUG: TEX_FILE_PATH=\"${TEX_PATH}/$1\" pdflatex -shell-escape \"$1\""
    # echo "Compiling $1..."
    fbase=$(basename "$1")
    TEX_FILE_PATH="${TEX_PATH}/${fbase}" pdflatex -shell-escape "${fbase}" && \
    cp "${BUILD_PATH}/${fbase%.*}.png" "${IMG_PATH}/${fbase%.*}.png"
}
export -f pdflatex_compile
pushd $BUILD_PATH

printf '%s\n' "${TEX_FILES[@]}" | parallel -j $PARALLEL_JOBS pdflatex_compile "{}"

popd

# Clean the build path
# rm -rf $BUILD_PATH
unset IFS
