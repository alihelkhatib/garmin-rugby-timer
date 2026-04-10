using Toybox.System;
using Toybox.Lang;

/**git r
 * Tiny, non-allocating profiler for quick hotspot measurement.
 *
 * Purpose: allow targeted local performance measurement without leaving
 * profiling overhead enabled in normal builds. Disabled by default.
 */
class Profiler {
    static var ENABLED = false;

    static function isEnabled() {
        return false;
    }

    static function start(key as Lang.String) {
        return;
    }

    static function stop(key as Lang.String) {
        return;
    }

    static function report() {
        return;
    }

    static function reset() {
        return;
    }
}
