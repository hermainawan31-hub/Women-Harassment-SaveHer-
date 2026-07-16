import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

/// Handles the "record audio during an SOS" add-on feature.
///
/// Flow:
///  1. As soon as an SOS is sent, [start] is called (fire-and-forget) with
///     the id of the sos_events document that was just created for the
///     user's SOS history, and recording begins immediately.
///  2. Recording keeps going until the user taps the small "Stop
///     Recording" button, which calls [stopAndSave].
///  3. On stop, the clip is read from disk, base64-encoded, and saved
///     entirely inside Firestore (no Firebase Storage involved). A single
///     Firestore document can only hold ~1 MiB, and any real recording's
///     base64 text is bigger than that, so the base64 string is split
///     into small chunks and written across a `recording_chunks`
///     sub-collection under the sos_events doc — the parent doc itself
///     only stores the file name and how many chunks to expect.
///  4. The same clip is then handed to the share sheet (Messages,
///     WhatsApp, etc.) with the saved emergency contact numbers already
///     filled into the message, so the user can immediately forward the
///     recording to them — plain SMS text alone can't carry an audio
///     attachment, so this is the reliable way to get the file itself to
///     a contact.
///
/// This is intentionally isolated from the rest of the SOS flow: nothing
/// here can throw back into `_performSos`, so it can never delay or break
/// the existing SMS / location alert behaviour.
class SosRecordingService {
  SosRecordingService._();

  static final AudioRecorder _recorder = AudioRecorder();

  // Stay safely under Firestore's ~1 MiB per-document limit (this is
  // characters of base64 text, plus a small "index" field alongside it).
  static const int _chunkSize = 700000;

  // The sos_events doc currently being recorded for, if any.
  static String? _activeSosEventId;
  static String? _activeFilePath;
  static String? _activeFileName;

  /// Whether a recording is currently in progress.
  static bool get isRecording => _activeSosEventId != null;

  /// Starts recording immediately and keeps recording until [stopAndSave]
  /// is called. Does not upload/save anything by itself.
  static Future<void> start(String sosEventId) async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return; // mic permission refused - skip silently

      final dir = await getTemporaryDirectory();
      final fileName =
          "sos_${sosEventId}_${DateTime.now().millisecondsSinceEpoch}.m4a";
      final filePath = "${dir.path}/$fileName";

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _activeSosEventId = sosEventId;
      _activeFilePath = filePath;
      _activeFileName = fileName;
    } catch (_) {
      _activeSosEventId = null;
      _activeFilePath = null;
      _activeFileName = null;
    }
  }

  /// Stops the current recording (if any), saves it entirely inside
  /// Firestore (chunked, with its file name) and opens the share sheet so
  /// it can be sent straight to the given [contactNumbers].
  ///
  /// Returns `true` if the recording was saved to Firestore successfully,
  /// `false` otherwise (e.g. nothing was recording, or the save failed) —
  /// the caller can use this to let the user know.
  static Future<bool> stopAndSave({
    List<String>? contactNumbers,
    String? callerName,
  }) async {
    final sosEventId = _activeSosEventId;
    final fallbackPath = _activeFilePath;
    final fileName = _activeFileName;
    _activeSosEventId = null;
    _activeFilePath = null;
    _activeFileName = null;

    if (sosEventId == null) return false; // nothing was recording

    File? file;
    try {
      final recordedPath = await _recorder.stop();
      final path = recordedPath ?? fallbackPath;
      if (path == null) return false;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      file = File(path);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final eventRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("sos_events")
          .doc(sosEventId);

      // Split the base64 text into chunks small enough to each fit
      // comfortably inside Firestore's per-document size limit, and
      // write them into their own sub-collection.
      final chunks = <String>[];
      for (var i = 0; i < base64Audio.length; i += _chunkSize) {
        final end = (i + _chunkSize < base64Audio.length)
            ? i + _chunkSize
            : base64Audio.length;
        chunks.add(base64Audio.substring(i, end));
      }

      // Firestore batches are capped at 500 writes — fine for any
      // realistic recording length, but guard against pathological cases
      // by writing in batches of 400 just in case.
      for (var start = 0; start < chunks.length; start += 400) {
        final end = (start + 400 < chunks.length)
            ? start + 400
            : chunks.length;
        final batch = FirebaseFirestore.instance.batch();
        for (var i = start; i < end; i++) {
          batch.set(eventRef.collection("recording_chunks").doc("$i"), {
            "index": i,
            "data": chunks[i],
          });
        }
        await batch.commit();
      }

      // The parent sos_events doc only stores small metadata — never the
      // audio itself — so it always stays well under the size limit.
      await eventRef.update({
        "recordingName": fileName,
        "recordingChunkCount": chunks.length,
        "recordingSavedAt": FieldValue.serverTimestamp(),
      });

      // Best-effort: open the share sheet with the clip itself so the
      // user can send it straight to their saved emergency contacts
      // (Messages/WhatsApp/etc.) — plain SMS text can't carry an audio
      // attachment, so this is the reliable way to get them the file.
      final numbers = (contactNumbers ?? [])
          .where((n) => n.trim().isNotEmpty)
          .toList();
      if (numbers.isNotEmpty) {
        try {
          await Share.shareXFiles(
            [XFile(path, name: fileName)],
            text:
                "🚨 SOS voice recording from ${callerName ?? 'me'}. "
                "Please send this to: ${numbers.join(', ')}",
            subject: "SafeHer SOS Recording",
          );
        } catch (_) {
          // sharing is best-effort too — never break the flow.
        }
      }

      return true;
    } catch (_) {
      // Save failed (e.g. no network, permissions) — caller decides how
      // to inform the user.
      return false;
    } finally {
      // Clean up the local temp copy either way.
      if (file != null) {
        unawaited(file.delete().catchError((_) => file!));
      }
    }
  }
}
