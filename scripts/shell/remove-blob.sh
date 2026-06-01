#!/usr/bin/env bash
CURRENT_PATH=$(pwd)
echo "Finding and removing all build artifacts..."

# Find and remove all node_modules
echo "Removing node_modules..."
find $CURRENT_PATH -type d -name "node_modules" -prune -exec rm -rf {} + 2>/dev/null

# Find and remove .next
echo "Removing .next..."
find $CURRENT_PATH -type d -name ".next" -prune -exec rm -rf {} + 2>/dev/null

# Find and remove dist/build/out
echo "Removing build directories..."
find $CURRENT_PATH -type d \( -name "dist" -o -name "build" -o -name "out" -o -name ".build" \) -prune -exec rm -rf {} + 2>/dev/null

# Find and remove .turbo
echo "Removing .turbo..."
find $CURRENT_PATH -type d -name ".turbo" -prune -exec rm -rf {} + 2>/dev/null

# Find and remove .vercel
echo "Removing .vercel..."
find $CURRENT_PATH -type d -name ".vercel" -prune -exec rm -rf {} + 2>/dev/null

# Find and remove cache directories
echo "Removing cache directories..."
find $CURRENT_PATH -type d \( -name ".cache" -o -name ".parcel-cache" -o -name ".vite" \) -prune -exec rm -rf {} + 2>/dev/null

# Find and remove temp directories
echo "Removing temp directories..."
find $CURRENT_PATH -type d \( -name "tmp" -o -name "temp" -o -name ".tmp" \) -prune -exec rm -rf {} + 2>/dev/null

# Find and remove coverage
echo "Removing coverage..."
find $CURRENT_PATH -type d -name "coverage" -prune -exec rm -rf {} + 2>/dev/null
