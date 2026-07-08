import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';

// ─── Privacy Policy Screen ────────────────────────────────────────────────────

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'سياسة الخصوصية',
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
                title: 'جمع البيانات',
                content:
                    'نقوم بجمع المعلومات التي تقدمها لنا مباشرة عند إنشاء حسابك، وتشمل: اسم المستخدم، الاسم المعروض، عنوان البريد الإلكتروني، الصورة الشخصية، والوصف البيو. كما نجمع بيانات الاستخدام تلقائياً مثل: نوع الجهاز، نظام التشغيل، عنوان IP، والتفاعلات داخل التطبيق (التغريدات، الإعجابات، المتابعات). قد نجمع بيانات الموقع الجغرافي إذا منحتنا الإذن بذلك.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 0,
              ),
              _buildSection(
                title: 'استخدام البيانات',
                content:
                    'نستخدم بياناتك لأغراض تشغيل الخدمة وتحسينها وتطويرها. يشمل ذلك: توفير وتخصيص تجربة المستخدم، إرسال الإشعارات المتعلقة بحسابك، تحليل أنماط الاستخدام لتحسين الخدمة، منع الاحتيال وإساءة الاستخدام، والتواصل معك بخصوص التحديثات والتغييرات. لن نبيع بياناتك الشخصية لأطراف ثالثة.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 50,
              ),
              _buildSection(
                title: 'مشاركة البيانات',
                content:
                    'قد نشارك بياناتك في الحالات التالية: مع موفري الخدمات الذين يساعدوننا في تشغيل التطبيق (مثل خدمات الاستضافة وقواعد البيانات)، استجابة للأوامر القضائية أو الطلبات القانونية، لحماية حقوقنا وسلامة المستخدمين والجمهور. لا نشارك بياناتك الشخصية مع أطراف ثالثة لأغراض تسويقية دون موافقتك الصريحة.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 100,
              ),
              _buildSection(
                title: 'التخزين',
                content:
                    'يتم تخزين بياناتك بشكل آمن على خوادم مؤسسة QTBM المزودة بأنظمة حماية متقدمة. يتم الاحتفاظ ببيانات حسابك طالما كان حسابك نشطاً. إذا قمت بحذف حسابك، سنقوم بحذف بياناتك الشخصية خلال فترة معقولة، مع الاحتفاظ ببعض البيانات المجهولة لأغراض إحصائية كما يقتضي القانون.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 150,
              ),
              _buildSection(
                title: 'الأمان',
                content:
                    'نتخذ إجراءات أمنية مناسبة لحماية بياناتك من الوصول غير المصرح به أو التغيير أو الإفشاء أو الإتلاف. نستخدم التشفير عند نقل البيانات وتخزينها. ومع ذلك، لا يمكن لأي نظام أمني أن يكون مضموناً بنسبة 100%، لذا ننصحك باستخدام كلمات مرور قوية وعدم مشاركة بيانات تسجيل الدخول.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 200,
              ),
              _buildSection(
                title: 'حقوقك',
                content:
                    'يحق لك: الوصول إلى بياناتك الشخصية المخزنة لدينا، طلب تصحيح أي بيانات غير دقيقة، طلب حذف بياناتك الشخصية (مع مراعاة التزاماتنا القانونية)، الاعتراض على معالجة بياناتك لأغراض تسويقية، وطلب نقل بياناتك بصيغة قابلة للقراءة. لممارسة أي من هذه الحقوق، تواصل معنا عبر m775371829@gmail.com.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 250,
              ),
              _buildSection(
                title: 'ملفات تعريف الارتباط',
                content:
                    'يستخدم التطبيق ملفات تعريف الارتباط وتقنيات مشابهة لتحسين تجربة الاستخدام وتحليل الأداء. يمكنك إدارة تفضيلات ملفات تعريف الارتباط من خلال إعدادات جهازك أو المتصفح. للحصول على تفاصيل أكثر، يرجى مراجعة سياسة ملفات تعريف الارتباط الخاصة بنا.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 300,
              ),
              _buildSection(
                title: 'التواصل',
                content:
                    'إذا كانت لديك أي أسئلة أو مخاوف بشأن سياسة الخصوصية هذه أو ممارسات حماية البيانات لدينا، يمكنك التواصل مع مؤسسة QTBM عبر البريد الإلكتروني: m775371829@gmail.com. سنقوم بالرد على استفساراتك في أقرب وقت ممكن.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 350,
              ),

              const SizedBox(height: 32),

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
    required String title,
    required String content,
    required Color textPrimary,
    required Color textSecondary,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with accent bar
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
            ),
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
          const SizedBox(height: 10),
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
    ).animate()
        .fadeIn(duration: 350.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.05, end: 0, duration: 350.ms);
  }
}