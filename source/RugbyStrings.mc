using Toybox.Lang;
using Toybox.WatchUi;
using Rez.Strings;

/**
 * Shared localized string helper for user-visible watch UI text.
 *
 * Purpose: keep resource loading and a small set of formatted labels in one
 * place so UI/runtime code does not mix localized resources with raw literals.
 */
class RugbyStrings {
    static function load(resourceId) {
        if (resourceId instanceof Lang.String) {
            return resourceId;
        }
        var value = WatchUi.loadResource(resourceId);
        if (value instanceof Lang.String) {
            return value;
        }
        return "";
    }

    static function getProfileLabel(profileId) {
        if (profileId == "7s") {
            return RugbyStrings.load(Rez.Strings.Profile_Rugby7s);
        } else if (profileId == "10s") {
            return RugbyStrings.load(Rez.Strings.Profile_Rugby10s);
        } else if (profileId == "u19") {
            return RugbyStrings.load(Rez.Strings.Profile_U19);
        } else if (profileId == "custom") {
            return RugbyStrings.load(Rez.Strings.Profile_Custom);
        }
        return RugbyStrings.load(Rez.Strings.Profile_Rugby15s);
    }

    static function getDefaultCustomProfileLabel() {
        return RugbyStrings.load(Rez.Strings.Profile_Custom);
    }

    static function getFormatLabel(is7s) {
        return is7s ? RugbyStrings.load(Rez.Strings.Format_7s) : RugbyStrings.load(Rez.Strings.Format_15s);
    }

    static function getTeamShortLabel(isHome) {
        return isHome ? RugbyStrings.load(Rez.Strings.Team_Home_Short) : RugbyStrings.load(Rez.Strings.Team_Away_Short);
    }

    static function getTeamMenuLabel(isHome) {
        return isHome ? RugbyStrings.load(Rez.Strings.Team_Home) : RugbyStrings.load(Rez.Strings.Team_Away);
    }

    static function getEventTeamLabel(isHome) {
        return isHome ? RugbyStrings.load(Rez.Strings.EventTeam_Home) : RugbyStrings.load(Rez.Strings.EventTeam_Away);
    }

    static function getCardPrefix(isRed) {
        return isRed ? RugbyStrings.load(Rez.Strings.CardPrefix_Red) : RugbyStrings.load(Rez.Strings.CardPrefix_Yellow);
    }

    static function getHalfText(halfNumber) {
        return RugbyStrings.load(Rez.Strings.HalfPrefix) + halfNumber.toString();
    }

    static function getTryText(tries) {
        return tries.toString() + RugbyStrings.load(Rez.Strings.TrySuffix);
    }

    static function getSecondsText(seconds) {
        return seconds.toLong().toString() + RugbyStrings.load(Rez.Strings.SecondsSuffix);
    }

    static function getOnOffLabel(enabled) {
        return enabled == true ? RugbyStrings.load(Rez.Strings.Generic_On) : RugbyStrings.load(Rez.Strings.Generic_Off);
    }
}
