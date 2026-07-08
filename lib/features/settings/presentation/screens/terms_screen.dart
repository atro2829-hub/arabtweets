import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';

// ─── Terms of Use Screen ──────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'شروط الاستخدام',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                number: '١',
                title: 'مقدمة',
                content:
                    'مرحباً بك في تطبيق Arabtweets ("الخدمة") الذي تديره مؤسسة QTBM ("نحن"، "لنا"، "إلينا"). تحكم شروط الاستخدام هذه ("الشروط") استخدامك للتطبيق والخدمات المرتبطة به. باستخدامك للخدمة، فإنك توافق على الالتزام بهذه الشروط.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٢',
                title: 'القبول والالتزام بالشروط',
                content:
                    'بإنشائك حساباً أو استخدامك لتطبيق Arabtweets، فإنك توافق على الالتزام بهذه الشروط بالكامل. إذا كنت لا توافق على أي جزء من هذه الشروط، يجب عليك عدم استخدام الخدمة. نحتفظ بالحق في تعديل هذه الشروط في أي وقت، وسيتم إخطارك بأي تغييرات جوهرية.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٣',
                title: 'التسجيل وحسابات المستخدمين',
                content:
                    'للتمكن من استخدام بعض ميزات الخدمة، يجب عليك إنشاء حساب. يجب أن تكون عمرك ١٣ عاماً على الأقل لإنشاء حساب. أنت مسؤول عن الحفاظ على سرية بيانات حسابك وكلمة المرور الخاصة بك وعن جميع الأنشطة التي تتم تحت حسابك. يجب عليك تقديم معلومات دقيقة وكاملة عند التسجيل وتحديثها في حالة تغيرها. لا يجوز لك إنشاء حسابات وهمية أو انتحال شخصية أخرى.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٤',
                title: 'المحتوى والسلوك المقبول',
                content:
                    'أنت المسؤول الوحيد عن المحتوى الذي تنشره عبر الخدمة. يُحظر عليك نشر محتوى يُشكل انتهاكاً لحقوق الغير، أو محتوى مسيء أو تحريضي أو عنيف أو مخل بالآداب العامة، أو محتوى ينتهك حقوق الملكية الفكرية، أو برامج ضارة أو فيروسات، أو محتوى يحث على الكراهية أو التمييز. نحتفظ بالحق في حذف أي محتوى ينتهك هذه الشروط دون إشعار مسبق. قد يؤدي الانتهاك المتكرر إلى تعليق أو إلغاء حسابك.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٥',
                title: 'الملكية الفكرية',
                content:
                    'يظل المحتوى الذي تنشره ملكاً لك، مع ذلك فإنك تمنحنا ترخيصاً غير حصري وعالمي وبدون رسوم لاستخدام هذا المحتوى وتوزيعه وعرضه لأغراض تشغيل الخدمة وتحسينها. التطبيق وشعاره وتصميمه وكل المحتوى الأصلي الخاص بنا هو ملك لمؤسسة QTBM ومحمي بموجب قوانين الملكية الفكرية المعمول بها.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٦',
                title: 'الخصوصية',
                content:
                    'نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. يتم جمع واستخدام بياناتك وفقاً لسياسة الخصوصية الخاصة بنا المتاحة عبر التطبيق. نستخدم بياناتك لتحسين الخدمة وتوفير تجربة مستخدم مخصصة وأغراض أمنية.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٧',
                title: 'إخلاء المسؤولية',
                content:
                    'يتم توفير الخدمة "كما هي" و"حسب التوفر" دون أي ضمانات صريحة أو ضمنية. لا نضمن أن الخدمة ستكون متاحة بشكل مستمر أو خالية من الأخطاء. لن نكون مسؤولين عن أي أضرار غير مباشرة أو عرضية أو تبعية ناتجة عن استخدامك للخدمة. لا نتحمل مسؤولية المحتوى الذي ينشره المستخدمون.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٨',
                title: 'التعديلات على الشروط',
                content:
                    'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم نشر الشروط المعدلة على هذه الصفحة مع تحديث تاريخ "آخر تحديث". استمرارك في استخدام الخدمة بعد نشر التعديلات يعني موافقتك على الشروط المعدلة. ننصحك بمراجعة هذه الشروط بشكل دوري.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '٩',
                title: 'التواصل',
                content:
                    'إذا كانت لديك أي أسئلة أو استفسارات بخصوص هذه الشروط، يمكنك التواصل معنا عبر البريد الإلكتروني: m775371829@gmail.com. فريق مؤسسة QTBM سيكون سعيداً بمساعدتك والإجابة على جميع استفساراتك.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildSection(
                number: '١٠',
                title: 'القانون المعمول به',
                content:
                    'تخضع هذه الشروط وتُفسّر وفقاً للقوانين المعمول بها. في حالة نشوء أي نزاع يتعلق بهذه الشروط، يتم حله بالطرق الودية أولاً، وفي حالة تعذر ذلك، يتم اللجوء إلى القضاء المختص. تظل الأحكام الأخرى من هذه الشروط سارية المفعول حتى في حالة بطلان أي حكم فيها.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 32),

              // ── Last Updated ───────────────────────────────────────────
              Center(
                child: Text(
                  'آخر تحديث: يوليو 2025',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Builder ────────────────────────────────────────────────────

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section number + title
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content paragraph
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
              height: 1.8,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (int.parse(number) * 50).ms)
        .slideY(begin: 0.05, end: 0, duration: 350.ms);
  }
}