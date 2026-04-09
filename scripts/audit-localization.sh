#!/usr/bin/env bash
set -euo pipefail

PATTERN='"(HOME|AWAY|PAUSED|CONVERSION|PENALTY KICK|HALF TIME|GAME ENDED|Custom|Rugby 7s|Rugby 10s|Rugby 15s|Profile|Format Family|Half Timer|Conversion Timer|Penalty Kick|Conversion Overlay|Penalty Overlay|Lock on Start|Dim Theme|Idle Hints|Reset Scores|Match Preset|Half Length \(min\)|Record Score|Pause/Resume Clock|Record Card|Start 2nd Half|End Game|Undo Last Score|Toggle Lock|Which Team\?|Home Score|Away Score|Try \(5\)|Penalty Try \(7\)|Drop Goal \(3\)|Card Team|Home Card|Away Card|Yellow|Red|Exit\?|Resume|Reset Game|Save Game|Event Log|Exit App|No events recorded|Save Log|Idle only|Save failed|Saved match reset|Action failed|Recording unsupported|Rugby sport unsupported|Recording start failed|Recording save failed)"'

TARGETS=(
  "source/RugbyTimerRenderer.mc"
  "source/RugbyTimerOverlay.mc"
  "source/RugbyTimerView.mc"
  "source/RugbySettingsNavigation.mc"
  "source/RugbySettingsPickers.mc"
  "source/RugbySettingsMenu.mc"
  "source/RugbyTimerMenus.mc"
  "source/RugbyTimerDelegate.mc"
  "source/RugbyGameModel.mc"
  "source/RugbyRecordingService.mc"
  "source/RugbyTimerPersistence.mc"
  "resources/layouts/layout.xml"
  "resources/menus/menu.xml"
)

if rg -n "${PATTERN}" "${TARGETS[@]}"; then
    echo "Localization audit failed: found hardcoded user-facing English in production files."
    exit 1
fi

echo "Localization audit passed."
