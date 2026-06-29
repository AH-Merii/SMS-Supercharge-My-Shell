#!/bin/bash
# Notification channel configuration
# Edit these to enable/disable notification channels

# Terminal bell — triggers tmux visual alert + Ghostty dock bounce
NOTIFY_BELL=true

# OSC 777 — native Ghostty desktop notification (auto-detects tmux passthrough)
NOTIFY_OSC=true

# Slack — via incoming webhook (requires webhook URL below)
NOTIFY_SLACK=false

# Slack incoming webhook URL (get from: https://api.slack.com/messaging/webhooks)
SLACK_WEBHOOK_URL=""
