import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';

// ─── Cookie Policy Screen ────────────────────────────────────────────────────

class CookiesScreen extends StatelessWidget {
  const CookiesScreen({super.key});

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
          'سياسة ملفات تعريف الارتباط',
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
              // ── What are cookies ──────────────────────────────────────
              _buildSection(
                title: 'ما هي ملفات تعريف الارتباط؟',
                content:
                    'ملفات تعريف الارتباط (Cookies) هي ملفات نصية صغيرة يتم تخزينها على جهازك عند زيارة تطبيقنا أو مواقعنا الإلكترونية. تساعد هذه الملفات في التعرف عليك وتذكر تفضيلاتك وتحسين تجربتك عند استخدام الخدمة.',
                textPrimary: textPrimary,
                delay: 0,
              ),

              _buildSection(
                title: 'أنواع ملفات تعريف الارتباط التي نستخدمها',
                content:
                    'نستخدم الأنواع التالية من ملفات تعريف الارتباط:\n\n'
                    '• ملفات أساسية (Essential Cookies): ضرورية لتشغيل التطبيق وتسجيل الدخول والحفاظ على جلسة المستخدم. لا يمكن تعطيلها.\n\n'
                    '• ملفات الأداء (Performance Cookies): تساعدنا في فهم كيفية تفاعل المستخدمين مع التطبيق وجمع بيانات إحصائية مجهولة.\n\n'
                    '• ملفات الوظائف (Functionality Cookies): تتيح تذكر تفضيلاتك مثل إعدادات اللغة والمظهر.\n\n'
                    '• ملفات التحليلات (Analytics Cookies): تُستخدم لتحليل أنماط الاستخدام وتحسين أداء الخدمة.',
                textPrimary: textPrimary,
                delay: 50,
              ),

              _buildSection(
                title: 'كيف نستخدم ملفات تعريف الارتباط',
                content:
                    'نستخدم ملفات تعريف الارتباط لضمان عمل التطبيق بشكل صحيح، تذكر تسجيل دخولك وتفضيلاتك، تحليل حركة المرور واستخدام التطبيق، تخصيص المحتوى والإعلانات، اكتشاف المشاكل التقنية وإصلاحها، وتحسين أداء التطبيق وسهولة استخدامه.',
                textPrimary: textPrimary,
                delay: 100,
              ),

              _buildSection(
                title: 'إدارة ملفات تعريف الارتباط',
                content:
                    'يمكنك التحكم في ملفات تعريف الارتباط من خلال إعدادات جهازك أو متصفحك. يمكنك حذف جميع ملفات تعريف الارتباط المخزنة على جهازك أو حظرها بالكامل. يرجى ملاحظة أن حظر ملفات تعريف الارتباط الأساسية قد يؤثر على وظائف التطبيق وقد لا تتمكن من استخدام بعض الميزات.',
                textPrimary: textPrimary,
                delay: 150,
              ),

              _buildSection(
                title: 'ملفات تعريف الارتباط من أطراف ثالثة',
                content:
                    'قد نسمح لأطراف ثالثة موثوقة بوضع ملفات تعريف الارتباط على جهازك لأغراض تحليلية أو تشغيلية. تخضع هذه الملفات لسياسات الخصوصية الخاصة بتلك الأطراف. لا نتحكم في ملفات تعريف الارتباط الخاصة بالأطراف الثالثة وننصحك بمراجعة سياسات الخصوصية الخاصة بهم.',
                textPrimary: textPrimary,
                delay: 200,
              ),

              _buildSection(
                title: 'تحديثات السياسة',
                content:
                    'قد نقوم بتحديث سياسة ملفات تعريف الارتباط هذه من وقت لآخر لتعكس التغييرات في التكنولوجيا أو المتطلبات القانونية. سيتم نشر أي تغييرات على هذه الصفحة مع تحديث تاريخ "آخر تحديث". استمرارك في استخدام الخدمة يعني موافقتك على السياسة المحدثة.',
                textPrimary: textPrimary,
                delay: 250,
              ),

              _buildSection(
                title: 'التواصل',
                content:
                    'إذا كانت لديك أي أسئلة حول استخدامنا لملفات تعريف الارتباط، يمكنك التواصل مع مؤسسة QTBM عبر البريد الإلكتروني: m775371829@gmail.com.',
                textPrimary: textPrimary,
                delay: 300,
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
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
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