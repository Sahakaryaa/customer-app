import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/service_region.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_colors.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// SahaKarya Assist — in-app support assistant.
/// Frontend-first architecture: [AssistantBrain] is a rule-based responder
/// today; swap its [reply] implementation for an API call later without any
/// UI changes.
/// ────────────────────────────────────────────────────────────────────────────

class AssistantReply {
  final String text;
  final List<String> followUps; // suggested next prompts
  final String? route; // optional deep-link the assistant can offer
  final String? routeLabel;
  const AssistantReply(this.text,
      {this.followUps = const [], this.route, this.routeLabel});
}

/// Rule-based brain. Deterministic, offline-safe, instant.
class AssistantBrain {
  const AssistantBrain();

  AssistantReply reply(String input, {required String userName}) {
    final q = input.toLowerCase().trim();

    // Greetings
    if (RegExp(r'^(hi|hello|hey|namaste|namaskaram)\b').hasMatch(q)) {
      return AssistantReply(
        'Namaste $userName! 👋 I\'m SahaKarya Assist. I can help you book a '
        'service, explain pricing, track a booking or find workers near you.',
        followUps: [
          'How is pricing decided?',
          'Book an electrician',
          'What is the welfare fund?',
        ],
      );
    }

    // Pricing
    if (q.contains('price') || q.contains('cost') || q.contains('pricing') ||
        q.contains('charge') || q.contains('fee') || q.contains('commission')) {
      final b = MockDataService.servicePrices;
      final lines = b.entries
          .map((e) => '• ${_cap(e.key)}: ₹${e.value['min']}–₹${e.value['max']}')
          .toList();
      return AssistantReply(
        'Our cooperative pricing is flat and transparent — no surge:\n\n'
        '${lines.join('\n')}\n\n'
        'Zero commission is taken from customers. Workers contribute exactly '
        '5% of each job to their welfare fund — compare that with the '
        '20–30% private apps take.',
        followUps: ['What is the welfare fund?', 'Book a cleaner'],
      );
    }

    // Welfare fund
    if (q.contains('welfare') || q.contains('fund') || q.contains('pension') ||
        q.contains('insurance')) {
      return AssistantReply(
        'Every booking contributes 5% of the service value into a federation-'
        'administered welfare fund. It funds pensions, medical cover and '
        'emergency grants for the workers you book — money that private '
        'platforms pocket as commission.',
        followUps: ['How do I book?', 'What areas do you serve?'],
      );
    }

    // Booking how-to
    if (q.contains('book') || q.contains('schedule') || q.contains('appointment')) {
      // Detect a service keyword inside the request
      for (final cat in MockDataService.serviceCategories) {
        if (q.contains(cat['id']!) || q.contains(cat['label']!.toLowerCase())) {
          return AssistantReply(
            'I can start that for you — tapping below opens ${cat['label']} '
            'partners near your location.',
            route: '/workers?service=${cat['id']}',
            routeLabel: 'Show ${cat['label']}s nearby',
            followUps: ['What are the rates?'],
          );
        }
      }
      return AssistantReply(
        'Booking takes under a minute: pick a service, pin your address on '
        'the map, choose a time slot and confirm. You\'ll see verified '
        'cooperative partners with live ETAs.',
        route: '/home',
        routeLabel: 'Browse all services',
        followUps: ['Book an electrician', 'How is pricing decided?'],
      );
    }

    // Emergency
    if (q.contains('urgent') || q.contains('emergency') || q.contains('asap') ||
        q.contains('immediately')) {
      return AssistantReply(
        'For urgent needs use Emergency Fast-Track on the home screen — it '
        'prioritises the closest online verified partner first.',
        route: '/workers?emergency=true',
        routeLabel: 'Start emergency dispatch',
      );
    }

    // Areas / coverage
    if (q.contains('area') || q.contains('serve') || q.contains('city') ||
        q.contains('where') || q.contains('location') || q.contains('region')) {
      return AssistantReply(
        'We operate across the ${ServiceRegion.displayName} — Anaparthi, '
        'Rajahmundry, Kakinada, Surampalem, Mandapeta and surrounding mandals '
        'of Andhra Pradesh.',
        followUps: ['How many workers are active?', 'How do I book?'],
      );
    }

    // Tracking / status
    if (q.contains('track') || q.contains('status') || q.contains('where is') ||
        q.contains('eta') || q.contains('late') || q.contains('delay')) {
      return AssistantReply(
        'You can see every active booking\'s live map, ETA and status timeline '
        'in the Recent Bookings section on home — tap one to open tracking.',
        route: '/history',
        routeLabel: 'View my bookings',
      );
    }

    // Cancellation & refunds
    if (q.contains('cancel') || q.contains('refund')) {
      return AssistantReply(
        'You can cancel free of charge until the partner marks "En Route" — '
        'open the booking from Recent Bookings and tap Cancel booking. '
        'Prepaid amounts return to source within 3–5 days.',
        route: '/history',
        routeLabel: 'Open my bookings',
      );
    }

    // Worker count / supply
    if (q.contains('how many') || q.contains('worker')) {
      return AssistantReply(
        'Over 180 verified cooperative workers are active across the region '
        'right now — electricians, plumbers, carpenters, cleaners, caregivers, '
        'drivers, painters and gardeners.',
        route: '/workers',
        routeLabel: 'See workers nearby',
      );
    }

    // Payment
    if (q.contains('pay') || q.contains('upi') || q.contains('cash')) {
      return AssistantReply(
        'Pay by UPI or cash after the job completes — you confirm the work '
        'first, then pay. The receipt shows exactly how much went to the '
        'worker and the welfare fund.',
        followUps: ['What is the welfare fund?'],
      );
    }

    // Safety
    if (q.contains('safe') || q.contains('sos') || q.contains('trust')) {
      return AssistantReply(
        'Every partner is verified by their labour cooperative federation with '
        'photo ID and skill certification. In-app chat and SOS connect you to '
        'the federation safety desk instantly during any booking.',
      );
    }

    // Fallback
    return AssistantReply(
      'I can help with bookings, pricing, welfare-fund questions, tracking '
      'and cancellations. Try one of these:',
      followUps: [
        'How do I book?',
        'How is pricing decided?',
        'What areas do you serve?',
      ],
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Floating assistant entry point + sheet. Drop onto any Scaffold's stack.
class SupportAssistantFAB extends StatelessWidget {
  final String userName;
  const SupportAssistantFAB({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'support_assistant_fab',
      onPressed: () {
        HapticFeedback.lightImpact();
        showSupportAssistantSheet(context, userName: userName);
      },
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.smart_toy_outlined),
    );
  }
}

void showSupportAssistantSheet(BuildContext context,
    {required String userName}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssistantSheet(userName: userName),
  );
}

class _AssistantSheet extends StatefulWidget {
  final String userName;
  const _AssistantSheet({required this.userName});

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantMsg {
  final String text;
  final bool isBot;
  final AssistantReply? reply;
  _AssistantMsg({required this.text, required this.isBot, this.reply});
}

class _AssistantSheetState extends State<_AssistantSheet> {
  static const _brain = AssistantBrain();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_AssistantMsg> _messages = [];
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_AssistantMsg(
          text:
              'Namaste ${widget.userName.split(' ').first}! I\'m SahaKarya '
              'Assist 🤝 Ask me anything about bookings, pricing or the '
              'welfare fund.',
          isBot: true,
          reply: const AssistantReply('', followUps: [
            'How do I book?',
            'How is pricing decided?',
            'What is the welfare fund?',
          ]),
        ));
      });
    });
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_AssistantMsg(text: trimmed, isBot: false));
      _input.clear();
    });
    _scrollDown();

    // Simulated thinking pause (short, purposeful).
    setState(() => _thinking = true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      final r = _brain.reply(trimmed, userName: widget.userName);
      setState(() {
        _thinking = false;
        _messages.add(_AssistantMsg(text: r.text, isBot: true, reply: r));
      });
      _scrollDown();
    });
  }

  bool _thinking = false;

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final viewInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top * 0.0 + 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SahaKarya Assist',
                                  style: GoogleFonts.sora(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                _thinking ? 'Typing…' : 'Always here to help',
                                style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: _thinking
                                        ? AppColors.success
                                        : AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Messages ──
            Flexible(
              child: ListView.builder(
                controller: _scroll,
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length +
                    (_thinking ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_thinking && i == _messages.length) {
                    return _botThinking(reducedMotion);
                  }
                  final m = _messages[i];
                  return _msgBubble(m, i, reducedMotion);
                },
              ),
            ),

            // ── Input ──
            Container(
              decoration: const BoxDecoration(color: AppColors.surface),
              padding: EdgeInsets.fromLTRB(
                  14, 8, 14, MediaQuery.of(context).padding.bottom + 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _send,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(fontSize: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ask about bookings, pricing…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.inkFaint),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_input.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _input.text.trim().isEmpty
                            ? null
                            : AppColors.primaryGradient,
                        color: _input.text.trim().isEmpty
                            ? AppColors.surfaceAlt
                            : null,
                      ),
                      child: Icon(Icons.arrow_upward_rounded,
                          size: 18,
                          color: _input.text.trim().isEmpty
                              ? AppColors.inkFaint
                              : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _msgBubble(_AssistantMsg m, int i, bool reducedMotion) {
    Widget w = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
              m.isBot ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: m.isBot ? AppColors.surface : AppColors.primaryDeep,
              borderRadius: BorderRadius.only(
                topLeft:
                    const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(m.isBot ? 5 : 18),
                bottomRight: Radius.circular(m.isBot ? 18 : 5),
              ),
              border:
                  m.isBot ? Border.all(color: AppColors.border) : null,
            ),
            child: Text(m.text,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    color: m.isBot ? AppColors.ink : Colors.white)),
          ),
        ),
        // Deep-link action button
        if (m.reply?.route != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                final route = m.reply!.route!;
                GoRouter.of(context).push(route);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: Text(m.reply!.routeLabel ?? 'Open',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        // Follow-up chips
        if (m.reply != null &&
            m.reply!.followUps.isNotEmpty &&
            i == _messages.length - 1)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: m.reply!.followUps.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, fi) {
                final chip = m.reply!.followUps[fi];
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
                      borderRadius: BorderRadius.circular(16)),
                  onPressed: () => _send(chip),
                );
              },
            ),
          ),
        const SizedBox(height: 2),
      ],
    );
    if (!reducedMotion && i >= _messages.length - 1) {
      w = w.animate().fade(duration: 220.ms).slideY(begin: 0.2, end: 0);
    }
    return w;
  }

  Widget _botThinking(bool reducedMotion) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18)
              .copyWith(bottomLeft: const Radius.circular(5)),
          border: Border.all(color: AppColors.border),
        ),
        child: reducedMotion
            ? const Text('…',
                style: TextStyle(color: AppColors.inkSoft))
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
                      .fade(begin: 0.25, end: 1,
                          delay: (i * 150).ms, duration: 450.ms);
                }),
              ),
      ),
    );
  }
}
