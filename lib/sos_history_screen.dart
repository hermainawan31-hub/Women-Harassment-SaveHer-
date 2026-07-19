import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'app_colors.dart';
import 'custom_app_bar.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'SOS History'),
      body: Column(
        children: [
          // ---- Gradient header ----
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + kToolbarHeight,
              20,
              26,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Tap any event to see the full details.",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // ---- List ----
          Expanded(
            child: user == null
                ? const _EmptyState(
                    message:
                        "You need to be signed in to view your SOS history.",
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .collection("sos_events")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _EmptyState(
                          message:
                              "Couldn't load history.\n${snapshot.error}",
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const _EmptyState(
                          message:
                              "No SOS alerts yet.\nStay safe — this is where your alert history will show up.",
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final eventRef = docs[index].reference;

                          final Timestamp? ts = data["timestamp"] as Timestamp?;
                          final DateTime? dateTime = ts?.toDate();

                          final String address =
                              (data["address"] ?? "Unknown location")
                                  .toString();

                          final String status =
                              (data["status"] ?? "Sent").toString();

                          final int recordingChunkCount =
                              (data["recordingChunkCount"] as num?)?.toInt() ??
                                  0;

                          final String recordingName =
                              (data["recordingName"] ?? "").toString();

                          final String recordingSavedAt =
                              (data["recordingSavedAt"] ?? "").toString();

                          final bool hasRecording =
                              recordingChunkCount > 0 ||
                              recordingName.isNotEmpty;

                          return _ExpandableHistoryCard(
                            dateTime: dateTime,
                            address: address,
                            status: status,
                            recordingChunkCount: recordingChunkCount,
                            recordingName: recordingName,
                            recordingSavedAt: recordingSavedAt,
                            hasRecording: hasRecording,
                            eventRef: eventRef,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPANDABLE CARD (using ExpansionTile)
// ============================================================
class _ExpandableHistoryCard extends StatelessWidget {
  final DateTime? dateTime;
  final String address;
  final String status;
  final int recordingChunkCount;
  final String recordingName;
  final String recordingSavedAt;
  final bool hasRecording;
  final DocumentReference<Map<String, dynamic>> eventRef;

  const _ExpandableHistoryCard({
    required this.dateTime,
    required this.address,
    required this.status,
    required this.recordingChunkCount,
    required this.recordingName,
    required this.recordingSavedAt,
    required this.hasRecording,
    required this.eventRef,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = dateTime != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(dateTime!)
        : "Unknown time";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDark.withOpacity(0.4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          title: Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Status: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Recording info
                if (hasRecording) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.audio_file_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recording",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark.withOpacity(0.75),
                                    ),
                                  ),
                                  if (recordingName.isNotEmpty)
                                    Text(
                                      recordingName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textDark.withOpacity(0.6),
                                      ),
                                    ),
                                  if (recordingSavedAt.isNotEmpty)
                                    Text(
                                      "Saved: $recordingSavedAt",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDark.withOpacity(0.5),
                                      ),
                                    ),
                                  if (recordingChunkCount > 0)
                                    Text(
                                      "Chunks: $recordingChunkCount",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDark.withOpacity(0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _RecordingPlayButton(eventRef: eventRef),
                            ),
                            const SizedBox(width: 10),
                            _RecordingSendButton(
                              eventRef: eventRef,
                              recordingName: recordingName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case "resolved":
        return const Color(0xFF2CB25A);
      case "cancelled":
        return AppColors.textDark.withOpacity(0.4);
      default:
        return AppColors.accent;
    }
  }
}

// ============================================================
// RECORDING PLAY BUTTON
// ============================================================
class _RecordingPlayButton extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> eventRef;
  const _RecordingPlayButton({required this.eventRef});

  @override
  State<_RecordingPlayButton> createState() => _RecordingPlayButtonState();
}

class _RecordingPlayButtonState extends State<_RecordingPlayButton> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => isPlaying = state == PlayerState.playing);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => isPlaying = false);
    });
  }

  Future<void> _toggle() async {
    if (isPlaying) {
      await _player.pause();
      return;
    }

    setState(() => isLoading = true);
    try {
      final eventSnap = await widget.eventRef.get();
      final data = eventSnap.data();

      final chunksSnap = await widget.eventRef
          .collection("recording_chunks")
          .orderBy("index")
          .get();

      if (chunksSnap.docs.isEmpty) {
        final legacy = data?["recordingBase64"] as String?;
        if (legacy != null && legacy.trim().isNotEmpty) {
          final bytes = base64Decode(legacy);
          await _player.play(BytesSource(bytes));
          setState(() => isLoading = false);
          return;
        }
        throw Exception("No recording found");
      }

      final base64Audio = chunksSnap.docs
          .map((d) => d.data()["data"] as String)
          .join();

      final bytes = base64Decode(base64Audio);
      await _player.play(BytesSource(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't play recording.")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _toggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 20,
                    ),
              const SizedBox(width: 8),
              Text(
                isPlaying ? "Playing…" : "Play recording",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECORDING SEND BUTTON (Share via WhatsApp/SMS/etc.)
// ============================================================
class _RecordingSendButton extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> eventRef;
  final String recordingName;
  const _RecordingSendButton({
    required this.eventRef,
    required this.recordingName,
  });

  @override
  State<_RecordingSendButton> createState() => _RecordingSendButtonState();
}

class _RecordingSendButtonState extends State<_RecordingSendButton> {
  bool isLoading = false;

  Future<void> _send() async {
    setState(() => isLoading = true);
    try {
      final eventSnap = await widget.eventRef.get();
      final data = eventSnap.data();

      final chunksSnap = await widget.eventRef
          .collection("recording_chunks")
          .orderBy("index")
          .get();

      List<int> bytes;
      if (chunksSnap.docs.isNotEmpty) {
        final base64Audio = chunksSnap.docs
            .map((d) => d.data()["data"] as String)
            .join();
        bytes = base64Decode(base64Audio);
      } else {
        final legacy = data?["recordingBase64"] as String?;
        if (legacy != null && legacy.trim().isNotEmpty) {
          bytes = base64Decode(legacy);
        } else {
          throw Exception("No recording found");
        }
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = widget.recordingName.isNotEmpty
          ? widget.recordingName
          : "sos_recording_${DateTime.now().millisecondsSinceEpoch}.m4a";
      final filePath = "${tempDir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "SOS recording",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't send recording.")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _send,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: AppColors.textDark.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}