using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Lang;
using Toybox.System;

/**
 * Activity-recording and GPS-track integration service.
 *
 * Purpose: isolate Connect IQ activity-session setup and live position capture
 * from gameplay state transitions. Recording is intentionally forced to
 * `Activity.SPORT_RUGBY` with no sport fallback.
 */
class RugbyRecordingService {
    static function startRecording(model) {
        if (!(Toybox has :ActivityRecording)) {
            model.setRecordingStatusMessage("Recording unsupported");
            return;
        }
        if (!(Activity has :SPORT_RUGBY)) {
            System.println("Activity recording unavailable: SPORT_RUGBY not supported");
            model.session = null;
            model.setRecordingStatusMessage("Rugby recording unavailable");
            return;
        }
        try {
            if (model.session == null) {
                model.session = ActivityRecording.createSession({
                    :name => "Rugby",
                    :sport => Activity.SPORT_RUGBY
                });
            }
            if (model.session != null && !model.session.isRecording()) {
                model.session.start();
            }
            model.setRecordingStatusMessage(null);
        } catch (ex) {
            System.println("Error starting activity recording: " + ex.getErrorMessage());
            model.session = null;
            model.setRecordingStatusMessage("Recording failed");
        }
    }

    static function stopRecording(model) {
        if (model.session == null) {
            return;
        }
        try {
            if (model.session.isRecording()) {
                model.session.stop();
            }
            model.session.save();
        } catch (ex) {
            System.println("Error stopping activity recording: " + ex.getErrorMessage());
        }
        model.session = null;
    }

    static function updatePosition(model, info) {
        model.positionInfo = info;
        if (info has :speed && info.speed != null) {
            model.speed = info.speed;
        }
        if (info has :distance && info.distance != null) {
            model.distance = info.distance;
        }
        if (info has :position && info.position != null) {
            try {
                var loc = info.position.toDegrees() as Lang.Array;
                model.gpsTrack.add({:lat => loc[0], :lon => loc[1]});
                if (model.gpsTrack.size() > model.MAX_TRACK_POINTS) {
                    model.gpsTrack.remove(0);
                }
            } catch (ex) {
                System.println("Error converting GPS position: " + ex.getErrorMessage());
            }
        }
    }
}
