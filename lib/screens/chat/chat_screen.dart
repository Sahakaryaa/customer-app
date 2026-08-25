import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// A single chat bubble message.
class ChatMsg {
  final String text;
  final bool isMine;
  final DateTime time;
  ChatMsg({required this.text, required this.isMine, required this.time});
}

/// Quick-reply chips shown above the input (Rapido/Uber pattern).
const List<String> kQuickReplies = [
  'I\'m at the gate',
  'Please call me',
  'Be there in 5 min',
  'Bring a ladder please',
];

/// In-trip chat between customer and service partner — polished bubbles,
/// quick replies, typing indicator, demo auto-replies when offline.
class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String peerName; // worker name for customer app
  final String? peerSkill;
  final String senderRole;
  final BookingChatTransport transport;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.peerName,
    required this.senderRole,
    required this.transport,
    this.peerSkill,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// Abstraction over the realtime layer so chat works with live Socket.IO
/// AND the offline demo simulation without redesigning the UI.
abstract class BookingChatTransport {
  /// Stream of incoming [ChatMsg]s.
  Stream<ChatMsg> incoming();

  /// Send [text]; return false if the channel is down so the screen can run
  /// its local demo fallback.
  bool send(String text);
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  final List<ChatMsg> _messages = [];
  StreamSubscription<ChatMsg>? _sub;
  bool _peerTyping = false;
  bool _showQuickReplies = true;
  Timer? _demoReplyTimer;

  @override
  void initState() {
    super.initState();
    _sub = widget.transport.incoming().listen(_onIncoming);
    _seedDemoHistory();
  }

  void _seedDemoHistory() {
    // Small seeded history so the thread never opens empty in demo mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _messages.isNotEmpty) return;
      setState(() {
        _messages.add(ChatMsg(
          text: 'On my way — will reach ${_shortTime(DateTime.now().add(const Duration(minutes: 8)))}.',
          isMine: false,
          time: DateTime.now().subtract(const Duration(minutes: 4)),
        ));
      });
      _jumpToEnd();
    });
  }

  static String _shortTime(DateTime t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  void _onIncoming(ChatMsg msg) {
    if (!mounted) return;
    setState(() {
      _peerTyping = false;
      _messages.add(msg);
    });
    _jumpToEnd();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    final sentLive = widget.transport.send(trimmed);

    setState(() {
      _messages
          .add(ChatMsg(text: trimmed, isMine: true, time: DateTime.now()));
      _showQuickReplies = false;
      _input.clear();
      if (!sentLive) _simulatePeerTyping();
    });
    _jumpToEnd();
  }

  /// Offline demo: peer "types" then answers from a small local brain so the
  /// chat feels real during presentations. Replaced by the live relay when
  /// the backend is connected.
  void _simulatePeerTyping() {
    _demoReplyTimer?.cancel();
    setState(() => _peerTyping = true);
    _demoReplyTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      const replies = [
        'Ok sir, noted 👍',
        'Sure, I\'m nearby only.',
        'Will do. Reaching soon.',
        'Thank you, I\'ll bring the tools.',
      ];
      final r = replies[math.Random().nextInt(replies.length)];
      setState(() {
        _peerTyping = false;
        _messages.add(ChatMsg(
            text: r, isMine: false, time: DateTime.now()));
      });
      _jumpToEnd();
    });
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _demoReplyTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                _initials(widget.peerName),
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.peerName,
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    _peerTyping ? 'typing…' : 'Service partner',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color:
                          _peerTyping ? AppColors.success : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Privacy note — mirrors Uber's chat disclaimer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    size: 13, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chat is monitored for safety and deleted after the booking ends.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length + (_peerTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (_peerTyping && i == _messages.length) {
                  return _typingBubble(reducedMotion);
                }
                final m = _messages[i];
                return _bubble(m, animateIn: !reducedMotion && i >= _messages.length - 1);
              },
            ),
          ),

          // Quick replies
          if (_showQuickReplies)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: kQuickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final chip = kQuickReplies[i];
                  return ActionChip(
                    label: Text(chip,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    onPressed: () => _send(chip),
                  );
                },
              ),
            ).animate().fade(duration: reducedMotion ? 1.ms : 250.ms),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _send,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Message $peerFirstName…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13.5, color: AppColors.inkFaint),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        filled: true,
                        fillColor: AppColors.bg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: reducedMotion ? 1 : 180),
                    curve: Curves.easeOut,
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _input.text.trim().isEmpty
                          ? null
                          : AppColors.primaryGradient,
                      color: _input.text.trim().isEmpty
                          ? AppColors.surfaceAlt
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 19,
                        color: _input.text.trim().isEmpty
                            ? AppColors.inkFaint
                            : Colors.white,
                      ),
                      onPressed:
                          _input.text.trim().isEmpty ? null : () => _send(_input.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMsg m, {required bool animateIn}) {
    final alignRight = m.isMine;
    Widget bubble = Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: alignRight ? 56 : 0,
        right: alignRight ? 0 : 56,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: alignRight ? AppColors.primaryDeep : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(alignRight ? 18 : 5),
          bottomRight: Radius.circular(alignRight ? 5 : 18),
        ),
        border: alignRight
            ? null
            : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.35,
              color: alignRight ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _clock(m.time),
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: alignRight
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
    if (animateIn) {
      bubble = bubble
          .animate()
          .fade(duration: 220.ms)
          .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
    }
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  Widget _typingBubble(bool reducedMotion) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(5),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: reducedMotion
            ? const Text('…', style: TextStyle(color: AppColors.inkSoft))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: const BoxDecoration(
                        color: AppColors.inkFaint, shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.25, end: 1, delay: (i * 150).ms, duration: 450.ms);
                }),
              ),
      ),
    );
  }

  String get peerFirstName => widget.peerName.split(' ').first;

  String _clock(DateTime t) =>
      '${((t.hour + 11) % 12) + 1}:${t.minute.toString().padLeft(2, '0')} '
      '${t.hour < 12 ? 'AM' : 'PM'}';

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join()
      .toUpperCase();
}

/// Live socket transport — wraps [BookingRealtimeService]-style objects that
/// expose chatStream/sendChatMessage. Kept untyped here to avoid circular
/// imports; the tracking screen constructs it.
class SocketChatTransport implements BookingChatTransport {
  final Stream<dynamic> chatStream;
  final bool Function(String) sendFn;
  final String bookingId;
  final String myRole;

  SocketChatTransport({
    required this.chatStream,
    required this.sendFn,
    required this.bookingId,
    required this.myRole,
  });

  @override
  Stream<ChatMsg> incoming() {
    return chatStream.where((cm) => cm.bookingId == bookingId).map<ChatMsg>(
        (cm) => ChatMsg(
              text: cm.text,
              isMine: cm.senderRole == myRole,
              time: cm.ts ?? DateTime.now(),
            ));
  }

  @override
  bool send(String text) => sendFn(text);
}
