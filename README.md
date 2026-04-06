# Rugby Timer App for Garmin Connect IQ

## Overview

The Rugby Timer is a comprehensive Garmin Connect IQ application designed for rugby enthusiasts, coaches, and referees. It provides a dedicated platform to accurately track game time, manage scores, monitor yellow and red cards, and handle key game states such as conversions, penalties, halftime, and full time. This app keeps the essential timing and scoring tools on your wrist for Rugby 7s, 10s, 15s, U19, and custom variants.

## Features

*   **Game Time Tracking:** Accurate tracking of match duration, with support for fully customizable half lengths and per-format defaults.
*   **Match Profiles:** One-tap starter presets for Rugby 7s, 10s, 15s, and U19, plus a persistent Custom profile for league-specific tweaks.
*   **Score Management:** Easily record tries, penalty tries, and drop goals for either team, with post-try conversions handled through the dedicated overlay.
*   **Card Management:** Implement yellow and red card timers with distinct durations for 7s and 15s rugby.
*   **Special Timers:** Dedicated countdowns for conversions and penalty kicks.
*   **Game State Awareness:** Visual indicators for various game states: Playing, Paused, Conversion, Penalty, Halftime, and Game Ended.
*   **Session Persistence:** Automatically saves game state and reopens an interrupted live match as a safe paused snapshot so play can be resumed cleanly after leaving the app or restarting the device.
*   **Event Logging:** Tracks significant game events for review.
*   **GPS Tracking (Optional):** Records distance and speed during activity for later analysis. If the app is closed mid-match, the current recording segment is saved and a new segment starts when play resumes.
*   **Vibration Alerts:** Distinct haptics for match start/pause/resume, half-time/full-time, conversion and penalty warnings/expiry, yellow-card warnings/expiry, and lock confirmation.
*   **UI Lock:** Prevents accidental button presses during intense gameplay.

## How to Use

1.  **Set the Half Length:** From the idle screen, use the Up/Down buttons to add or subtract one minute immediately. The main countdown updates in place.
2.  **Choose a Variant:** Hold `MENU` to open Settings, then select a `Profile` while the app is idle. Built-in presets cover Rugby 7s, 10s, 15s, and U19, and any manual timing edits automatically become part of the saved `Custom` profile.
3.  **Start/Pause/Resume Game:** Use the `Select` button to toggle between playing and paused states.
4.  **Record Scores:** Use the `Previous Page` button to access the scoring menu (Try, Penalty Try, Drop Goal). Recording a try automatically opens the conversion overlay so the referee can log made or missed kicks from the main screen.
5.  **Record Cards:** Use the `Next Page` button to access the card management menu (Yellow Card, Red Card).
6.  **Undo Events / Open Settings:** Short-press `MENU` for the in-app match menu (undo, event log, lock, etc.). Hold `MENU` to jump straight into Settings.
7.  **Lock/Unlock UI:** Toggle the UI lock from the main menu to prevent accidental input.
8.  **Exit Game:** Use the `Back` button to bring up the exit menu, where you can choose to resume, end, reset, or save the game.

## Garmin Connect IQ App Store Information

### Short Description
Rugby Timer for Garmin - Track scores, cards, and game time for 7s, 10s, 15s, U19, and custom matches.

### Long Description
The ultimate Rugby Timer for your Garmin Connect IQ device! This app empowers referees, coaches, and players to manage rugby matches with precision and ease. Track tries, penalty tries, and drop goals, run conversion and penalty-kick countdowns, and manage dynamic yellow and red card timers. After each try, the conversion overlay appears automatically so the referee can record make or miss directly from the main screen. With automatic session persistence, you can seamlessly resume any ongoing game. Get real-time game state feedback, distinct vibration alerts for the moments that matter, and optional GPS tracking for performance analysis. Designed for Rugby 7s, 10s, 15s, U19, and custom rule sets, this app is your essential companion for every rugby game.

### Screenshots
*   (Placeholder for Main Timer Screen - Playing State)
*   (Placeholder for Score Entry Menu)
*   (Placeholder for Card Timer Display)
*   (Placeholder for Pause/Halftime Screen)

### Keywords
Rugby, Timer, Score, Cards, Yellow Card, Red Card, Game Time, 7s, 15s, Referee, Coach, Sports, GPS, Activity, Match, Countdown, Connect IQ, Garmin

### Supported Devices
Compiler-validated manifest targets currently cover the Fenix 6/7/8/E families plus vivoactive 5/6. Several Garmin sibling watches share those same Connect IQ product ids, so the Fenix targets also cover related tactix, quatix, and Enduro variants that map to the same device definitions.

## Maintenance Notes

- The project maintenance roadmap lives in [`docs/MAINTENANCE_ROADMAP.md`](docs/MAINTENANCE_ROADMAP.md).
- The watch-facing manual regression checklist lives in [`tests/README.md`](tests/README.md) alongside the automated test instructions.
- Source design/reference PNG assets that are not consumed by the app build live under [`docs/assets/`](docs/assets/) so the project root stays focused on build inputs and repo-level docs.

---

## What's New - Version 1.0.0

*   **Initial Release:**
    *   Comprehensive game time tracking for Rugby 7s, 10s, 15s, U19, and custom profiles.
    *   Full score management (tries, conversions, penalties, drop goals).
    *   Yellow and red card timers with specific durations.
    *   Special countdowns for conversions and penalty kicks.
    *   Automatic session saving and resuming.
    *   Event logging for significant game actions.
    *   Configurable vibration alerts for key events.
    *   UI lock feature to prevent accidental touches.
    *   Optional GPS tracking.

---

## Version Release Notes

### Version 1.0.0 (December 12, 2025)
*   **Initial Public Release:** This version introduces the core functionality of the Rugby Timer application. It includes robust time management, scoring features, and card tracking essential for managing rugby matches.
*   **Key Features:**
    *   Accurate game time and countdowns.
    *   Detailed score recording.
    *   Dynamic yellow and red card timers.
    *   Seamless session persistence.
    *   Intuitive user interface for match management.
    *   Customizable game types (7s/15s) with appropriate timings.

---
