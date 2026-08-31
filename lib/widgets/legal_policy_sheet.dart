import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum LegalDocType { privacyPolicy, termsOfService, cooperativeCharter }

/// Comprehensive, beautifully rendered legal & policy sheet for SahaKarya.
class LegalPolicySheet extends StatelessWidget {
  final LegalDocType initialDoc;

  const LegalPolicySheet({
    super.key,
    this.initialDoc = LegalDocType.privacyPolicy,
  });

  static Future<void> show(BuildContext context, {LegalDocType doc = LegalDocType.privacyPolicy}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalPolicySheet(initialDoc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: switch (initialDoc) {
        LegalDocType.privacyPolicy => 0,
        LegalDocType.termsOfService => 1,
        LegalDocType.cooperativeCharter => 2,
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal & Policies',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'SahaKarya Labour Cooperative Federation',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.inkSoft,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Privacy Policy'),
                Tab(text: 'Terms of Service'),
                Tab(text: 'Co-op Charter'),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildPrivacyPolicy(),
                  _buildTermsOfService(),
                  _buildCooperativeCharter(),
                ],
              ),
            ),

            // Bottom action
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'I Understand & Agree',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. Non-Extractable Data Dignity',
          content:
              'SahaKarya operates as a transparent labour cooperative platform. We collect only data strictly necessary to match customers with certified tradespeople and calculate fair pricing. We never sell, broker, or monetize your personal information to third-party ad networks.',
        ),
        _section(
          title: '2. Location & GPS Tracking',
          content:
              'GPS coordinates are used in real-time only during active service discovery and live transit dispatching. Location data is stored using protected geospatial indexing and is not tracked when the application is idle.',
        ),
        _section(
          title: '3. Communication & In-Trip Chat',
          content:
              'In-trip messaging and calling are encrypted and restricted to the active booking duration to protect both customer and service partner privacy.',
        ),
        _section(
          title: '4. Data Retention & Account Rights',
          content:
              'You have full ownership of your data. You may request complete export or deletion of your account and booking history at any time through the Federation grievance portal.',
        ),
      ],
    );
  }

  Widget _buildTermsOfService() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. Cooperative Platform Agreement',
          content:
              'By accessing SahaKarya, you agree to engage with cooperative workers fairly and respectfully. All workers on our platform are certified cooperative members entitled to fair living wages.',
        ),
        _section(
          title: '2. Transparent Standardized Pricing',
          content:
              'Service tariffs are transparently fixed by the Federation Council. No surge multipliers or arbitrary price gouging are applied during emergencies.',
        ),
        _section(
          title: '3. Booking & Cancellation Policy',
          content:
              'Cancellations made after a service partner is en-route may incur a nominal transit reimbursement fee to cover the worker’s fuel and opportunity cost.',
        ),
        _section(
          title: '4. Dispute Resolution',
          content:
              'Any service quality grievances are resolved by the Labour Cooperative Federation ombudsman within 48 hours with guaranteed mediation.',
        ),
      ],
    );
  }

  Widget _buildCooperativeCharter() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          title: '1. Democratic Member Ownership',
          content:
              'SahaKarya is governed by the Labour Cooperative Federation under the principles of democratic member control, open membership, and worker autonomy.',
        ),
        _section(
          title: '2. 5% Non-Extractable Welfare Allocation',
          content:
              'Every completed booking allocates exactly 5% towards the collective Worker Welfare Fund. This fund finances healthcare stipends, tool insurance, and emergency family aid.',
        ),
        _section(
          title: '3. Dignity in Labour',
          content:
              'We uphold fair treatment, safety standards, and mutual respect between customers and tradespeople across all service categories.',
        ),
      ],
    );
  }

  Widget _section({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
