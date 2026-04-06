## Class Interactions within the Rugby Timer Garmin App

This document outlines the main interaction patterns and communication flows between the core classes of the Rugby Timer Garmin application.

### Core Components and Their Roles

*   **`RugbyTimerApp.mc`**: The application's entry point and lifecycle manager. It initializes the main application components and handles global application events.
*   **`RugbyGameModel.mc`**: The central data model and business logic hub. It holds the entire state of the game and provides methods for state transitions and updates. It is the single source of truth for all game-related data.
*   **`RugbyTimerView.mc`**: The main user interface renderer. It is responsible for displaying the current state of the game to the user.
*   **`RugbyTimerDelegate.mc`**: The primary handler for user input and interactions. It translates user actions into operations on the game model or UI.
*   **`RugbyTimerPersistence.mc`**: A utility class responsible for saving and loading the application's game state.
*   **`RugbyTimerTiming.mc`**: A utility class encapsulating the core logic for game timing, including the main game clock and card timers.
*   **`RugbyTimerCards.mc`**: A utility class dedicated to managing the state and logic of yellow and red cards.
*   **`RugbyTimerEventLog.mc`**: A utility class for logging significant in-game events and providing functionality for displaying or exporting these logs.

### Interaction Flows

#### 1. Application Initialization and Lifecycle (`RugbyTimerApp.mc`)

*   **`RugbyTimerApp` initializes `RugbyGameModel`, `RugbyTimerView`, and `RugbyTimerDelegate`:**
    *   `RugbyTimerApp`'s `getInitialView()` method is where these core components are instantiated and linked.
    *   `RugbyTimerApp` passes the `RugbyGameModel` instance to `RugbyTimerView` and `RugbyTimerDelegate` during their initialization.
*   **Event Handling:**
    *   `RugbyTimerApp` receives global events (e.g., GPS updates via `onPosition`) and forwards relevant data to `RugbyGameModel` (`model.updatePosition(info)`).
    *   `RugbyTimerApp` also manages the overall application flow, including showing settings views (e.g., `getSettingsView`).

#### 2. Model-View-Delegate (MVD) Pattern

The application primarily adheres to the MVD pattern:

*   **`RugbyGameModel` to `RugbyTimerView` (Model -> View):**
    *   `RugbyTimerView` reads the current state directly from `RugbyGameModel` (e.g., `model.homeScore`, `model.gameTime`, `model.gameState`, `model.yellowHomeTimes`) to render the UI.
    *   `RugbyTimerView` calls methods on `RugbyTimerRenderer` to draw specific UI elements based on the model's data.
    *   `RugbyTimerView` interacts with `RugbyTimerOverlay` to manage and render overlay elements.

*   **`RugbyTimerDelegate` to `RugbyGameModel` (Delegate -> Model):**
    *   `RugbyTimerDelegate` captures user input (button presses, menu selections).
    *   Based on user input, `RugbyTimerDelegate` calls methods on `RugbyGameModel` to update the game state (e.g., `model.startGame()`, `model.recordTry(isHome)`, `model.adjustScore(isHome, delta)`).

*   **`RugbyTimerDelegate` to `RugbyTimerView` (Delegate -> View):**
    *   In some cases, `RugbyTimerDelegate` directly interacts with `RugbyTimerView` to trigger UI actions (e.g., `view.showScoreDialog()`, `view.toggleLock()`, `view.closeSpecialTimerScreen()`).

#### 3. Inter-Module Communication (Model and Utility Classes)

*   **`RugbyGameModel` and `RugbyTimerPersistence.mc`:**
    *   `RugbyGameModel` initiates saving and loading: `RugbyTimerPersistence.saveState(self)` and `RugbyTimerPersistence.loadSavedState(self)`.
    *   `RugbyTimerPersistence` directly accesses and modifies fields of the `RugbyGameModel` instance passed to it to perform serialization/deserialization.

*   **`RugbyGameModel` and `RugbyTimerTiming.mc`:**
    *   `RugbyGameModel`'s `updateGame()` method calls `RugbyTimerTiming.updateGame(self)` in every update cycle.
    *   `RugbyTimerTiming` then updates various time-related fields within the `RugbyGameModel` (e.g., `model.gameTime`, `model.countdownRemaining`).
    *   `RugbyTimerTiming` also calls `RugbyTimerCards.updateYellowTimers()` to update card timers.

*   **`RugbyGameModel` and `RugbyTimerCards.mc`:**
    *   `RugbyGameModel` calls `RugbyTimerCards.allocateYellowCardId(self, isHome)`, `RugbyTimerCards.clearCardTimers(self)`, `RugbyTimerCards.updateYellowTimers()`.
    *   `RugbyTimerCards` modifies card-related fields within `RugbyGameModel` (e.g., `model.yellowHomeTimes`, `model.redHome`).

*   **`RugbyGameModel` and `RugbyTimerEventLog.mc`:**
    *   `RugbyGameModel` calls `RugbyTimerEventLog.appendEntry(self, description)` to log events.
    *   `RugbyTimerEventLog` also has `exportEventLog` and `showEventLog` which `RugbyGameModel` can trigger.

*   **`RugbyTimerRenderer.mc`:**
    *   This class contains static methods (e.g., `renderScores`, `renderGameTimer`, `renderCardTimers`, `renderStateText`).
    *   These methods are primarily called by `RugbyTimerView` to perform the actual drawing operations on the device context (`dc`).
    *   `RugbyTimerRenderer` reads data directly from `RugbyGameModel` (passed as a parameter) to determine what to draw.

#### Summary of Data Flow

*   **User Input:** `RugbyTimerDelegate` -> `RugbyGameModel` (state change) or `RugbyTimerView` (UI action).
*   **Game Logic/State Updates:** `RugbyGameModel` (self-contained logic) <-> `RugbyTimerTiming`, `RugbyTimerCards`, `RugbyTimerPersistence`, `RugbyTimerEventLog`.
*   **UI Rendering:** `RugbyTimerApp` -> `RugbyTimerView` -> `RugbyGameModel` (read state) and `RugbyTimerRenderer` (draw elements). `RugbyTimerView` also manages `RugbyTimerOverlay`.

This modular design ensures a clear separation of concerns, making the codebase easier to understand, maintain, and extend.