using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;

/**
 * Storage write guardrails for persisted app state.
 *
 * Purpose: validate payload shapes before they hit Garmin Storage so runtime
 * autosaves fail safely in debug logs instead of surfacing device-only schema
 * errors during live match flows.
 */
class RugbyStorageSupport {
    static function isSafeScalar(value) {
        return value == null
            || value == true
            || value == false
            || value instanceof Lang.String
            || value instanceof Lang.Number
            || value instanceof Lang.Float;
    }

    static function findUnsupportedValuePath(value, path) {
        if (RugbyStorageSupport.isSafeScalar(value)) {
            return null;
        }

        if (value instanceof Lang.Array) {
            var items = value as Lang.Array;
            for (var i = 0; i < items.size(); i = i + 1) {
                var childPath = RugbyStorageSupport.findUnsupportedValuePath(items[i], path + "[" + i.toString() + "]");
                if (childPath != null) {
                    return childPath;
                }
            }
            return null;
        }

        if (value instanceof Lang.Dictionary) {
            var dict = value as Lang.Dictionary;
            var keys = dict.keys();
            for (var k = 0; k < keys.size(); k = k + 1) {
                var key = keys[k];
                if (!(key instanceof Lang.String)) {
                    return path + ".<non-string-key>";
                }
                var keyText = key as Lang.String;
                var entryPath = path + "." + keyText;
                var child = RugbyStorageSupport.findUnsupportedValuePath(dict[keyText], entryPath);
                if (child != null) {
                    return child;
                }
            }
            return null;
        }

        return path;
    }

    static function setValue(key, value) {
        var keyText = key != null ? key.toString() : "<null-key>";
        var unsupportedPath = RugbyStorageSupport.findUnsupportedValuePath(value, keyText);
        if (unsupportedPath != null) {
            System.println("Refusing to persist unsupported value at " + unsupportedPath);
            return false;
        }

        try {
            Storage.setValue(key, value);
            return true;
        } catch (ex) {
            System.println("Storage write failed for " + keyText + ": " + ex.getErrorMessage());
            return false;
        }
    }
}
