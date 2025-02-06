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


# Check if template file exists
if [ ! -f "$TEX_PATH/_template.tex" ]; then
    echo "Template file not found: $TEX_PATH/_template.tex"
    exit 1
fi

# Collect all tex files
TEX_FILES=($(find tex -type f -name "*.tex" -not -name "_template.tex"))
echo Found "${#TEX_FILES[@]}" tex files: "${TEX_FILES[@]}"

# If not FORCE, exclude files that already have images
PNG_FILES=$(find img -type f -name "*.png")
if [ $FORCE -eq 0 ]; then
    TEX_FILES=($(for f in "${TEX_FILES[@]}"; do
        f=$(basename "$f")
        if [[ ! " $PNG_FILES " =~ " $IMG_PATH/${f%.*}.png " ]]; then
            echo "$f"
        fi
    done))
fi

# Make sure the "parallel" is installed
if ! command -v parallel &> /dev/null; then
    echo "The 'parallel' command is required but it's not installed. Aborting."
    exit 1
fi

# Create build folder
mkdir -p "${BUILD_PATH}"
BUILD_PATH=$(realpath "${BUILD_PATH}")

# Copy the template into build files
for f in "${TEX_FILES[@]}"; do
    echo "Processing $f"
    cp $TEX_PATH/_template.tex "$BUILD_PATH/${f%.*}.tex"
done

# Compile the tex files in the build directory in parallel
pdflatex_compile() {
    # echo "===> DEBUG: TEX_FILE_PATH=\"${TEX_PATH}/$1\" pdflatex -shell-escape \"$1\""
    TEX_FILE_PATH="$TEX_PATH/$1" pdflatex -shell-escape "$1" && \
    cp "$BUILD_PATH/${1%.*}.png" "$IMG_PATH/${1%.*}.png"
}
export -f pdflatex_compile
pushd $BUILD_PATH

printf '%s\n' "${TEX_FILES[@]}" | 
    # parallel -j $PARALLEL_JOBS pdflatex -shell-escape "{}"
    parallel -j $PARALLEL_JOBS pdflatex_compile "{}"

popd

# Clean the build path
# rm -rf $BUILD_PATH
unset IFS
