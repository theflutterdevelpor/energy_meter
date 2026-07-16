import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';



class AppColors {
  static const Color background = Color(0xFF0A0E14);
  static const Color card = Color(0xFF141A24);
  static const Color cardBorder = Color(0xFF232B38);
  static const Color green = Color(0xFF3ECF6B);
  static const Color greenGlow = Color(0x553ECF6B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A93A3);
  static const Color chipInactive = Color(0xFF1C2330);
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  static const String appName = "WattPro";
  static const String appLogo = "assets/images/app_logo.png";
  static const String appDescription =
      "Smart Energy Monitor helps you track your home or office electricity "
      "usage in real time. The app also provides energy saving tips and "
      "detailed usage reports.";

  static const List<Map<String, String>> features = [
    {
      "title": "Real-Time Monitoring",
      "desc": "Track your electricity usage live.",
    },
    {
      "title": "Usage Reports",
      "desc": "View daily, weekly, and monthly reports.",
    },
    {
      "title": "Smart Alerts",
      "desc": "Get notified when usage is unusually high.",
    },
    {
      "title": "Energy Saving Tips",
      "desc": "Useful tips to help you save electricity.",
    },
  ];

  static const String developerName = "Merik Solutions";
  static const String contactEmail = "admin@meriksolutions.biz";
  static const String contactPhone = "+92 300 1234567";
  static const String website = "https://www.example.com";
  static const String privacyPolicyUrl = "https://www.example.com/privacy-policy";
  static const String termsUrl = "https://www.example.com/terms-and-conditions";
  static const String copyrightText = "© 2026 Merik Solutions. All rights reserved.";

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _versionText = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionText = "Version ${info.version}";
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      debugPrint("Could not launch email");
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      debugPrint("Could not launch phone");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "About",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GlowCard(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    AboutScreen.appLogo,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 42,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AboutScreen.appName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  ),
                  child: Text(
                    _versionText,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle(title: "Description"),
          const SizedBox(height: 10),
          _DarkCard(
            child: Text(
              AboutScreen.appDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle(title: "Features"),
          const SizedBox(height: 10),
          _DarkCard(
            child: Column(
              children: List.generate(AboutScreen.features.length, (index) {
                final f = AboutScreen.features[index];
                final isLast = index == AboutScreen.features.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check,
                                size: 16, color: AppColors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f["title"]!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  f["desc"]!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, color: AppColors.cardBorder),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle(title: "Developer"),
          const SizedBox(height: 10),
          _DarkCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Developed & maintained by",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AboutScreen.developerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle(title: "Contact Us"),
          const SizedBox(height: 10),
          _DarkCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: AboutScreen.contactEmail,
                  onTap: () => _launchEmail(AboutScreen.contactEmail),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: "Phone",
                  value: AboutScreen.contactPhone,
                  onTap: () => _launchPhone(AboutScreen.contactPhone),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                _InfoRow(
                  icon: Icons.language_outlined,
                  label: "Website",
                  value: AboutScreen.website,
                  onTap: () => _launchUrl(AboutScreen.website),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle(title: "Legal"),
          const SizedBox(height: 10),
          _DarkCard(
            child: Column(
              children: [
                _NavRow(
                  icon: Icons.privacy_tip_outlined,
                  label: "Privacy Policy",
                  onTap: () => _launchUrl(AboutScreen.privacyPolicyUrl),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                _NavRow(
                  icon: Icons.description_outlined,
                  label: "Terms & Conditions",
                  onTap: () => _launchUrl(AboutScreen.termsUrl),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                _NavRow(
                  icon: Icons.code_outlined,
                  label: "Open Source Licenses",
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: AboutScreen.appName,
                      applicationVersion: _versionText,
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          AboutScreen.appLogo,
                          width: 50,
                          height: 50,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.bolt,
                              size: 50,
                              color: AppColors.green),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              AboutScreen.copyrightText,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}


class _GlowCard extends StatelessWidget {
  final Widget child;
  const _GlowCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: AppColors.greenGlow,
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.green, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.green, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}