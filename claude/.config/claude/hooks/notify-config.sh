#!/bin/bash
# Notification channel configuration
# Edit these to enable/disable notification channels

# Terminal bell — triggers tmux visual alert + Ghostty dock bounce
NOTIFY_BELL=true

# OSC 777 — native Ghostty desktop notification (auto-detects tmux passthrough)
NOTIFY_OSC=true

# macOS Notification Center — via terminal-notifier (requires: brew install terminal-notifier)
NOTIFY_MACOS=true

# Slack — via incoming webhook (requires webhook URL below)
NOTIFY_SLACK=false

# Slack incoming webhook URL (get from: https://api.slack.com/messaging/webhooks)
SLACK_WEBHOOK_URL=""

# macOS notification icon — bundle ID of app whose icon to use
MACOS_SENDER="com.mitchellh.ghostty"
