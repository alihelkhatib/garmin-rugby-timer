using Toybox.Lang;

const RUGBY_NOTICE_CHANNEL_TOAST = "toast";

/**
 * Typed wrapper for one-shot runtime notices shown by the app.
 *
 * Purpose: keep user-visible operational notices explicit instead of routing
 * arbitrary raw strings through view and overlay state.
 */
class RugbyRuntimeNotice {
    var message;
    var channel;

    static function create(message, channel) {
        if (!(message instanceof Lang.String) || message.length() == 0) {
            return null;
        }
        var notice = new RugbyRuntimeNotice();
        notice.message = message;
        notice.channel = channel != null ? channel : RUGBY_NOTICE_CHANNEL_TOAST;
        return notice;
    }

    static function fromValue(raw) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof RugbyRuntimeNotice) {
            return raw;
        }
        if (raw instanceof Lang.String) {
            return RugbyRuntimeNotice.create(raw, RUGBY_NOTICE_CHANNEL_TOAST);
        }
        if (raw instanceof Lang.Dictionary) {
            var dict = raw as Lang.Dictionary;
            return RugbyRuntimeNotice.create(dict["message"], dict["channel"]);
        }
        return null;
    }

    function toDict() {
        return {
            "message" => message,
            "channel" => channel
        };
    }
}
