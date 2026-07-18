import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import 'app_colors.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "SOS History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ---- Gradient header ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
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

                          // ✅ FIELDS FROM YOUR FIRESTORE
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
            // ---- Expanded details ----
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
                  Row(
                    children: [
                      const Icon(
                        Icons.audio_file_rounded,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recording:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark.withOpacity(0.7),
                              ),
                            ),
                            if (recordingName.isNotEmpty)
                              Text(
                                recordingName,
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
                  const SizedBox(height: 10),
                  _RecordingPlayButton(eventRef: eventRef),
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

      // Try to get recording from chunks sub-collection
      final chunksSnap = await widget.eventRef
          .collection("recording_chunks")
          .orderBy("index")
          .get();

      if (chunksSnap.docs.isEmpty) {
        // Try legacy field
        final legacy = data?["recordingBase64"] as String?;
        if (legacy != null && legacy.trim().isNotEmpty) {
          final bytes = base64Decode(legacy);
          await _player.play(BytesSource(bytes));
          setState(() => isLoading = false);
          return;
        }
        throw Exception("No recording found");
      }

      // Build base64 from chunks
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
    return InkWell(
      onTap: isLoading ? null : _toggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: AppColors.primary,
                    size: 20,
                  ),
            const SizedBox(width: 6),
            Text(
              isPlaying ? "Playing…" : "Play recording",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
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