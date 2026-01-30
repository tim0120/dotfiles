#!/bin/bash

# Claude Code Task Completion Notification Script
# Cross-platform: works on macOS and Linux, silently skips if no sound available

# macOS
if [[ "$(uname)" == "Darwin" ]] && command -v afplay &> /dev/null; then
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    exit 0
fi

# Linux with PulseAudio
if command -v paplay &> /dev/null; then
    # Try common notification sounds
    for sound in /usr/share/sounds/freedesktop/stereo/complete.oga \
                 /usr/share/sounds/gnome/default/alerts/glass.ogg \
                 /usr/share/sounds/ubuntu/stereo/message.ogg; do
        if [[ -f "$sound" ]]; then
            paplay "$sound" 2>/dev/null &
            exit 0
        fi
    done
fi

# Linux with ALSA (fallback)
if command -v aplay &> /dev/null; then
    for sound in /usr/share/sounds/*.wav; do
        if [[ -f "$sound" ]]; then
            aplay -q "$sound" 2>/dev/null &
            exit 0
        fi
    done
fi

# No sound available - silent exit (not an error)
exit 0
