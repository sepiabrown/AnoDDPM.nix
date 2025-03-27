#!/usr/bin/env -S nix shell nixpkgs#imagemagick --command bash

# Check if a directory name is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_name>"
    exit 1
fi

# Set input and output directories
INPUT_DIR="DATASETS/$1/train/good"
OUTPUT_DIR="DATASETS/$1/train/good_processed"

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist."
    exit 1
fi

echo "Converting $INPUT_DIR"
# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all .png images in the input directory
for image_path in "$INPUT_DIR"/*.png; do
    # Check if the glob didn't match any files
    if [ ! -e "$image_path" ]; then
        echo "No .png files found in '$INPUT_DIR'."
        break
    fi

    # Extract the filename from the path
    filename=$(basename "$image_path")

    # Get image dimensions
    dimensions=$(identify -format "%wx%h" "$image_path")
    width=${dimensions%x*}
    height=${dimensions#*x}

    # Define crop size
    crop_size=256

    # Ensure the image is large enough for cropping
    if [ "$width" -lt "$crop_size" ] || [ "$height" -lt "$crop_size" ]; then
        echo "Skipping '$filename': image is smaller than ${crop_size}x${crop_size}."
        continue
    fi

    # Calculate maximum x and y offsets for cropping
    max_x=$((width - crop_size))
    max_y=$((height - crop_size))

    # Generate random x and y offsets within the allowable range
    x_offset=$((RANDOM % (max_x + 1)))
    y_offset=$((RANDOM % (max_y + 1)))

    # Process the image: convert to grayscale and perform random crop
    magick "$image_path" -colorspace Gray -crop "${crop_size}x${crop_size}+${x_offset}+${y_offset}" +repage "$OUTPUT_DIR/$filename"
done

echo "Conversion Finished"
