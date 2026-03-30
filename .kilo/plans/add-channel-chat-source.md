# Plan: Add CHAT_MSG_CHANNEL support

## Summary

Add `CHAT_MSG_CHANNEL` to the chat events table so the addon captures players from all numbered channels (General, Trade, LFG, WorldDefense, custom).

## Why no channel filter?

`CHAT_MSG_CHANNEL` fires for every numbered channel. Filtering to just "LookingForGroup" would:
- Miss players in General, Trade, WorldDefense
- Require fragile localized string matching (channel names differ by client language)
- Add complexity for no benefit — the throttle + insert-only DB already prevent spam/duplicates

Channel join/leave system messages are automatically excluded because they have nil `senderGUID`, which the existing `if senderGUID then` guard already rejects.

## Changes

**File: `Core.lua`** — single edit.

Add `"CHAT_MSG_CHANNEL"` to the `CHAT_EVENTS` table (line ~247):

```lua
local CHAT_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL",
}
```

No other changes — the existing handler branch, pcall, throttle, `CollectChatData`, and `DebugPrint` calls all work as-is because `CHAT_MSG_CHANNEL` shares the same arg layout (arg2 = sender name, arg12 = sender GUID).

## Commit

```
git commit -m"feat(core): add channel chat passive data source"
```
