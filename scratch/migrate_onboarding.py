import re

def update_slide_language():
    file_path = 'lib/features/onboarding/widgets/onboarding_slide_language.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import if missing
    if "import '../../../../core/locales/app_localizations.dart';" not in content:
        content = "import '../../../../core/locales/app_localizations.dart';\n" + content

    # Replace hero banner
    content = content.replace(
        """            const OnboardingHeroBanner(
              badgeText: 'Akses Ramah Lansia',
              stageText: 'TAHAP 1 DARI 3',
              title: 'Pilih Bahasa Kenyamanan',
              icon: Icons.mosque,
            ),""",
        """            OnboardingHeroBanner(
              badgeText: context.tr('onboarding.elderlyAccess'),
              stageText: context.tr('onboardingStage1'),
              title: context.tr('onboarding.chooseLanguageTitle'),
              icon: Icons.mosque,
            ),"""
    )

    # Replace stepper label
    content = content.replace(
        "label: '1 DARI 3 TAHAP AWAL',",
        "label: context.tr('onboarding.stage1Of3'),"
    )

    # Replace section header call & method
    content = content.replace(
        "_buildLanguageHeader(),",
        "_buildLanguageHeader(context),"
    )
    content = content.replace(
        "Widget _buildLanguageHeader() {",
        "Widget _buildLanguageHeader(BuildContext context) {"
    )
    content = content.replace(
        "'Bahasa Pengantar',",
        "context.tr('onboarding.introTitle'),"
    )
    content = content.replace(
        "'Pilih bahasa yang paling mudah dipahami selama ibadah.',",
        "context.tr('onboarding.introDesc'),"
    )

    # Replace intro description
    content = content.replace(
        "'Pilih bahasa yang paling mudah dipahami untuk kenyamanan ibadah dan komunikasi darurat Anda.',",
        "context.tr('onboarding.chooseLanguageDesc'),"
    )

    # Replace languages dynamic list
    old_grid = """                itemBuilder: (context, index) {
                  final lang = _languages[index];"""
    new_grid = """                final languages = [
                  ('id', 'Indonesia', context.tr('onboarding.indonesiaSubtitle'), context.tr('onboarding.mainLanguage')),
                  ('jv', 'Basa Jawi', context.tr('onboarding.jawiSubtitle'), context.tr('onboarding.regionalLanguage')),
                  ('su', 'Basa Sunda', context.tr('onboarding.sundaSubtitle'), context.tr('onboarding.regionalLanguage')),
                  ('en', 'English', context.tr('onboarding.englishSubtitle'), context.tr('onboarding.globalLanguage')),
                ];

                return GridView.builder(
                  itemCount: languages.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final lang = languages[index];"""
    content = content.replace(
        """              return GridView.builder(
                itemCount: _languages.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final lang = _languages[index];""",
        new_grid
    )

    # Replace hint footer
    content = content.replace(
        "'Ukuran teks dan panduan audio akan otomatis disesuaikan dengan bahasa yang dipilih.',",
        "context.tr('onboarding.audioGuideHint'),"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated onboarding_slide_language.dart")

def update_slide_safety():
    file_path = 'lib/features/onboarding/widgets/onboarding_slide_safety.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if "import '../../../../core/locales/app_localizations.dart';" not in content:
        content = "import '../../../../core/locales/app_localizations.dart';\n" + content

    content = content.replace(
        """            const OnboardingHeroBanner(
              badgeText: 'Sistem Keselamatan Jamaah',
              stageText: 'TAHAP 2 DARI 3',
              title: 'Jaga Jarak Aman & Terpantau',
              icon: Icons.shield,
            ),""",
        """            OnboardingHeroBanner(
              badgeText: context.tr('onboarding.safetySystemBadge'),
              stageText: context.tr('onboardingStage2'),
              title: context.tr('onboarding.safetySlideTitle'),
              icon: Icons.shield,
            ),"""
    )

    content = content.replace(
        "label: '2 DARI 3 TAHAP AWAL',",
        "label: context.tr('onboarding.stage2Of3'),"
    )

    content = content.replace(
        "_buildSectionHeader(),",
        "_buildSectionHeader(context),"
    )
    content = content.replace(
        "Widget _buildSectionHeader() {",
        "Widget _buildSectionHeader(BuildContext context) {"
    )
    content = content.replace(
        "'Fitur Keselamatan Jamaah',",
        "context.tr('onboarding.safetyFeaturesHeader'),"
    )
    content = content.replace(
        "'Teknologi pendampingan cerdas agar jamaah tetap aman dan terhubung selama ibadah.',",
        "context.tr('onboarding.safetyFeaturesSub'),"
    )

    content = content.replace(
        """            _buildFeatureCard(
              icon: Icons.near_me,
              title: 'Pendamping Aman',
              description:
                  'Pantau rombongan secara real-time dan terima peringatan otomatis saat terpisah melebihi batas aman.',
              badgeText: 'Radar Aktif',""",
        """            _buildFeatureCard(
              icon: Icons.near_me,
              title: context.tr('onboarding.safeCompanion'),
              description: context.tr('onboarding.safeCompanionDesc'),
              badgeText: context.tr('onboarding.radarActive'),"""
    )

    content = content.replace(
        """            _buildFeatureCard(
              icon: Icons.map,
              title: 'Peta Terpadu & SOS',
              description:
                  'Temukan pos kesehatan, hotel, dan hubungi bantuan darurat hanya dengan satu sentuhan.',
              badgeText: 'SOS 24 Jam',""",
        """            _buildFeatureCard(
              icon: Icons.map,
              title: context.tr('onboarding.integratedMapSos'),
              description: context.tr('onboarding.integratedMapSosDesc'),
              badgeText: context.tr('onboarding.sos24h'),"""
    )

    content = content.replace(
        """            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: 'Ramah Jamaah Lansia',
              description:
                  'Ukuran tombol besar, kontras tinggi, dan mudah digunakan di bawah terik matahari.',
              badgeText: 'Ramah Lansia',""",
        """            _buildFeatureCard(
              icon: Icons.accessibility_new,
              title: context.tr('onboarding.elderlyFriendly'),
              description: context.tr('onboarding.elderlyFriendlyDesc'),
              badgeText: context.tr('onboarding.elderlyFriendly'),"""
    )

    content = content.replace(
        "_buildSafetyFooter(),",
        "_buildSafetyFooter(context),"
    )
    content = content.replace(
        "Widget _buildSafetyFooter() {",
        "Widget _buildSafetyFooter(BuildContext context) {"
    )
    content = content.replace(
        "'Notifikasi getar dan suara otomatis aktif untuk membantu jamaah tetap aman selama perjalanan.',",
        "context.tr('onboarding.safetyFooterNote'),"
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated onboarding_slide_safety.dart")

def update_slide_accessibility():
    file_path = 'lib/features/onboarding/widgets/onboarding_slide_accessibility.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if "import '../../../../core/locales/app_localizations.dart';" not in content:
        content = "import '../../../../core/locales/app_localizations.dart';\n" + content

    content = content.replace(
        """            const OnboardingHeroBanner(
              badgeText: 'Aksesibilitas Ramah Lansia & Disabilitas',
              stageText: 'TAHAP 3 DARI 3',
              title: 'Mudah Diakses Siapa Saja',
              icon: Icons.accessibility_new,
              height: 180,
            ),""",
        """            OnboardingHeroBanner(
              badgeText: context.tr('onboarding.accessSlideBadge'),
              stageText: context.tr('onboardingStage3'),
              title: context.tr('onboarding.accessSlideTitle'),
              icon: Icons.accessibility_new,
              height: 180,
            ),"""
    )

    content = content.replace(
        "label: '3 DARI 3 TAHAP AWAL',",
        "label: context.tr('onboarding.stage3Of3'),"
    )

    content = content.replace(
        "_buildAccessibilityHeader(),",
        "_buildAccessibilityHeader(context),"
    )
    content = content.replace(
        "Widget _buildAccessibilityHeader() {",
        "Widget _buildAccessibilityHeader(BuildContext context) {"
    )
    content = content.replace(
        "'Fitur Kemudahan',",
        "context.tr('onboarding.accessFeaturesHeader'),"
    )
    content = content.replace(
        "'Membantu jamaah lansia dan disabilitas beribadah lebih nyaman.',",
        "context.tr('onboarding.accessFeaturesSub'),"
    )

    content = content.replace(
        """            Text(
              'Bantuan cerdas deteksi uang riyal dan komunikasi suara & isyarat untuk kelancaran ibadah jamaah lansia dan berkebutuhan khusus.',""",
        """            Text(
              context.tr('onboarding.accessIntro'),"""
    )

    content = content.replace(
        """            _buildSlide3FeatureCard(
              icon: Icons.payments_outlined,
              title: 'Scan Uang Riyal',
              description:
                  'Arahkan kamera ke lembaran riyal, nominal langsung terdeteksi dan dibacakan otomatis via suara (Text-to-Speech).',
            ),""",
        """            _buildSlide3FeatureCard(
              icon: Icons.payments_outlined,
              title: context.tr('onboarding.scanRiyal'),
              description: context.tr('onboarding.scanRiyalDesc'),
            ),"""
    )

    content = content.replace(
        """            _buildSlide3FeatureCard(
              icon: Icons.mic_outlined,
              title: 'Komunikasi & Isyarat',
              description:
                  'Konversi bicara ke teks besar serta ungkapan darurat cepat (Tolong, Sakit, Air) yang mudah dimengerti warga lokal.',
              badgeText: 'SUARA & TEKS',
            ),""",
        """            _buildSlide3FeatureCard(
              icon: Icons.mic_outlined,
              title: context.tr('onboarding.commGestures'),
              description: context.tr('onboarding.commGesturesDesc'),
              badgeText: context.tr('onboarding.voiceAndText'),
            ),"""
    )

    content = content.replace(
        """                    child: Text(
                      'Text-to-Speech dan bantuan suara siap digunakan untuk membantu jamaah selama perjalanan ibadah.',""",
        """                    child: Text(
                      context.tr('onboarding.ttsReady'),"""
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated onboarding_slide_accessibility.dart")

if __name__ == '__main__':
    update_slide_language()
    update_slide_safety()
    update_slide_accessibility()
