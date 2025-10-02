#!/bin/bash
# Reset LaundryPets test data by resetting the simulator

echo "🔄 Resetting iOS Simulator..."

# Close simulator if running
osascript -e 'quit app "Simulator"'

# Get the booted device UUID
DEVICE_UUID=$(xcrun simctl list devices | grep "(Booted)" | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})" | head -1)

if [ -z "$DEVICE_UUID" ]; then
    echo "⚠️  No booted simulator found. Boot a simulator first."
    exit 1
fi

echo "📱 Found device: $DEVICE_UUID"

# Erase all content and settings for this device
xcrun simctl erase $DEVICE_UUID

echo "✅ Simulator reset complete! Data is clean."
echo "▶️  Run the app again for fresh start."

