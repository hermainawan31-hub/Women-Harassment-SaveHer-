
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
                    "A record of every SOS alert you've triggered.",
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
                          message: "Couldn't load history.\n${snapshot.error}",
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final Timestamp? ts = data["timestamp"] as Timestamp?;
                          final DateTime? dateTime = ts?.toDate();
                          final String address =
                              (data["address"] ?? "Unknown location")
                                  .toString();
                          final String status = (data["status"] ?? "Sent")
                              .toString();

                          final int chunkCount =
                              (data["recordingChunkCount"] as num?)
                                  ?.toInt() ??
                              0;
                          final bool hasRecording =
                              chunkCount > 0 ||
                              (data["recordingBase64"] as String?)
                                      ?.trim()
                                      .isNotEmpty ==
                                  true;


                          return _HistoryCard(
                            dateTime: dateTime,
                            address: address,
                            status: status,
                            hasRecording: hasRecording,
                            eventRef: docs[index].reference,

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

class _HistoryCard extends StatelessWidget {
  final DateTime? dateTime;
  final String address;
  final String status;

  final bool hasRecording;
  final DocumentReference<Map<String, dynamic>> eventRef;

  const _HistoryCard({
    required this.dateTime,
    required this.address,
    required this.status,

    required this.hasRecording,
    required this.eventRef,

  });

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

  @override
  Widget build(BuildContext context) {
    final formattedDate = dateTime != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(dateTime!)
        : "Unknown time";

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textDark.withOpacity(0.55),
                  ),
                ),


                if (hasRecording) ...[
                  const SizedBox(height: 8),
                  _RecordingPlayButton(eventRef: eventRef),
                ],

              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

      // Legacy fallback: a couple of early recordings were saved as a
      // single "recordingBase64" field before chunking was added.
      final legacy = data?["recordingBase64"] as String?;

      String base64Audio;
      if (legacy != null && legacy.trim().isNotEmpty) {
        base64Audio = legacy;
      } else {
        final chunksSnap = await widget.eventRef
            .collection("recording_chunks")
            .orderBy("index")
            .get();

        if (chunksSnap.docs.isEmpty) {
          throw Exception("No recording found");
        }

        base64Audio = chunksSnap.docs
            .map((d) => d.data()["data"] as String)
            .join();
      }

      final bytes = base64Decode(base64Audio);
      await _player.play(BytesSource(bytes));
    } catch (_) {
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
