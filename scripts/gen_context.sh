#!/bin/sh

# Script to create content.txt with directory structure, file listings, and contents
# Compatible with Alpine Linux (ash/busybox)
# Usage: ./generate_content.sh

NOW=`date '+%Y_%m_%d_%H_%M'`
OUTPUT_FILE="$NOW.content.txt"

# Clear the output file if it exists
> "$OUTPUT_FILE"

echo "Generating content.txt..."

# 0. Get the date
echo "===============================================" >> "$OUTPUT_FILE"
echo -n "UPDATED AT " >> "$OUTPUT_FILE"; echo $NOW >> "$OUTPUT_FILE"
echo "===============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 1. Add directory tree

echo "===============================================" >> "$OUTPUT_FILE"
echo "DIRECTORY TREE STRUCTURE" >> "$OUTPUT_FILE"
echo "===============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if command -v tree >/dev/null 2>&1; then
    tree -a -I '.git' ~/inception >> "$OUTPUT_FILE"
else
    # Fallback if tree command is not available
    find . -type d | sed 's|[^/]*/|  |g' >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. Add ls -laR output
echo "===============================================" >> "$OUTPUT_FILE"
echo "RECURSIVE FILE LISTING (ls -laR)" >> "$OUTPUT_FILE"
echo "===============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
ls -laR ~/inception/scripts >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
ls -laR ~/inception/secrets >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
ls -laR ~/inception/srcs >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 3. Add file contents
echo "===============================================" >> "$OUTPUT_FILE"
echo "FILE CONTENTS" >> "$OUTPUT_FILE"
echo "===============================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# RECURSIVE FILE READING: The 'find' command searches recursively from the current 
# directory (.) through ALL subdirectories for regular files (-type f).
# Each file found is then read with 'cat' to display its content.
# This ensures files in nested subdirectories are included.
find ~/inception/srcs -type f ! -name "$OUTPUT_FILE" | while read -r file; do
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    echo "File: $file" >> "$OUTPUT_FILE"
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    
    # Check if file is readable
    if [ -r "$file" ]; then
        # Try to detect binary files - Alpine compatible method
        if command -v file >/dev/null 2>&1; then
            # If 'file' command exists, use it
            if file "$file" | grep -q "text"; then
                cat "$file" >> "$OUTPUT_FILE"
            else
                echo "[Binary file - content not displayed]" >> "$OUTPUT_FILE"
            fi
        else
            # Fallback: try to read the file, but be aware it might be binary
            # Check for null bytes as indicator of binary content
            if grep -q '\x00' "$file" 2>/dev/null; then
                echo "[Binary file detected - content not displayed]" >> "$OUTPUT_FILE"
            else
                cat "$file" >> "$OUTPUT_FILE"
            fi
        fi
    else
        echo "[File not readable - permission denied]" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

find ~/inception/secrets -type f ! -name "$OUTPUT_FILE" | while read -r file; do
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    echo "File: $file" >> "$OUTPUT_FILE"
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    
    # Check if file is readable
    if [ -r "$file" ]; then
        # Try to detect binary files - Alpine compatible method
        if command -v file >/dev/null 2>&1; then
            # If 'file' command exists, use it
            if file "$file" | grep -q "text"; then
                cat "$file" >> "$OUTPUT_FILE"
            else
                echo "[Binary file - content not displayed]" >> "$OUTPUT_FILE"
            fi
        else
            # Fallback: try to read the file, but be aware it might be binary
            # Check for null bytes as indicator of binary content
            if grep -q '\x00' "$file" 2>/dev/null; then
                echo "[Binary file detected - content not displayed]" >> "$OUTPUT_FILE"
            else
                cat "$file" >> "$OUTPUT_FILE"
            fi
        fi
    else
        echo "[File not readable - permission denied]" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "-----------------------------------------------" >> "$OUTPUT_FILE"
echo "File: Makefile" >> "$OUTPUT_FILE"
echo "-----------------------------------------------" >> "$OUTPUT_FILE"

cat ~/inception/Makefile >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo "-----------------------------------------------" >> "$OUTPUT_FILE"
echo "Scripts" >> "$OUTPUT_FILE"
echo "-----------------------------------------------" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
find ~/inception/scripts -type f ! -name "$OUTPUT_FILE" | while read -r file; do
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    echo "File: $file" >> "$OUTPUT_FILE"
    echo "-----------------------------------------------" >> "$OUTPUT_FILE"
    
    # Check if file is readable
    if [ -r "$file" ]; then
        # Try to detect binary files - Alpine compatible method
        if command -v file >/dev/null 2>&1; then
            # If 'file' command exists, use it
            if file "$file" | grep -q "text"; then
                cat "$file" >> "$OUTPUT_FILE"
            else
                echo "[Binary file - content not displayed]" >> "$OUTPUT_FILE"
            fi
        else
            # Fallback: try to read the file, but be aware it might be binary
            # Check for null bytes as indicator of binary content
            if grep -q '\x00' "$file" 2>/dev/null; then
                echo "[Binary file detected - content not displayed]" >> "$OUTPUT_FILE"
            else
                cat "$file" >> "$OUTPUT_FILE"
            fi
        fi
    else
        echo "[File not readable - permission denied]" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
done

echo "Content generation complete! Output saved to $OUTPUT_FILE"
