import 'package:flutter/material.dart';

import '../../../component/theme/app_colors.dart';
import '../../../model/setting/faq_item.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: '월급이 일정하지 않아요! 이 경우엔 어떻게 월 수입을 입력하나요? 😟',
      answer:
      '월급이 들쭉날쭉한 프리랜서, 일용직, 자영업자 분들은 최근 3~6개월간의 수입 평균을 입력하는 걸 추천드려요 🙂\n\n👉 평균치를 기준으로 계획을 세우면 더 현실적인 플랜 설정이 가능해요!',
    ),
    FAQItem(
      question: '적금이나 청약도 고정 지출에 포함되나요? 🤔',
      answer:
      '❌ 아니요! 적금, 청약, 투자 등은 **고정 지출이 아닌 \'저축 항목\'**입니다.\n\n👉 고정 지출에는 월세, 통신비, 보험료처럼 매달 자동으로 나가는 소비성 지출만 입력해주세요.',
    ),
    FAQItem(
      question: '목표 금액은 꼭 있어야 하나요? 😊',
      answer:
      '물론이죠! 🎯 목표 금액이 있어야 내가 얼마를 아끼고, 얼마나 모아야 하는지 계산할 수 있어요.\n\n👉 아직 명확한 목표가 없다면, 추천 금액 중에서 선택해도 괜찮아요. (100만, 300만, 500만... 등)',
    ),
    FAQItem(
      question: '자동 등록 서비스는 뭔가요? 🧐',
      answer:
      '사용자가 소비를 미기록한 날에도, 미리 설정해둔 평일/주말 예산 기준으로 소비를 자동 기록해주는 기능이에요.\n\n👉 "바빠서 기록 못했어요😥" → "자동으로 입력돼 있어서 놓치지 않았어요!"\n\n단, 설정한 항목에만 적용돼요. 자동 입력은 다음 접속 시 언제든 수정 가능해요!',
    ),
    FAQItem(
      question: '계획을 수정하고 싶으면 어떻게 하나요? 😌',
      answer:
      '언제든지 마이페이지에서 수정 가능해요!\n\n👉 수입, 고정 지출, 목표 금액, 생활비, 자동 등록 항목 전부 다 다시 설정할 수 있어요.\n\n변경 즉시 앱에 반영되고, 목표 달성일도 자동 재계산된답니다 😊',
    ),
    FAQItem(
      question: '하루 소비 한도 금액이 뭔가요? 💭',
      answer:
      '하루 소비 한도는 내가 설정한 **한 달 생활비(변동 소비 예산)**를 기준으로\n\n📅 30일 또는 31일로 나눈 일일 평균 지출 가능 금액이에요.\n\n예: 한 달 생활비가 60만 원이면 → 하루 소비 한도는 약 20,000원!\n\n👉 이 한도는 앱이 내 소비 패턴을 분석하고, 목표 달성 날짜를 계산하는 데 기준이 돼요 😊',
    ),
    FAQItem(
      question: '하루 소비 한도보다 더 쓰거나, 덜 쓰면 어떻게 돼요? 😅',
      answer:
      '🎯 이 앱의 핵심 기능이에요!\n\n앱은 매일의 소비가 하루 한도보다 초과/절약되었는지 실시간으로 체크하고,\n그 차이를 **시간(초 단위)**로 바꿔서 목표 도달 시점을 앞당기거나 늦춰줘요.\n\n예시\n✅ 오늘 절약: 3,000원 → 목표 달성 시각 4시간 당겨짐\n❌ 오늘 초과: 4,000원 → 목표 달성 시각 5시간 늦어짐\n\n👉 이런 변화는 홈 화면의 타이머에도 즉시 반영돼요.\n👀 내가 얼마나 잘 아끼고 있는지 실시간으로 확인할 수 있죠!',
    ),
    FAQItem(
      question: '저는 투자하고 있어요, 투자는 소통 어플에서 어떻게 기록하나요? 🤷',
      answer:
      '소통에서는 사용자님의 투자 기록을 가져올 수 없어요. 목표 금액에는 **순수 저축**만 반영돼요.\n\n소통 앱에는 투자 내역이 등록되지 않지만, 투자를 하시면서 소통에서는 저축과 소비만 꾸준히 기록하시면 자산 형성에 훨씬 도움이 돼요 😊',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark
        ? (Colors.grey[900] ?? Colors.black)
        : Colors.white;
    final Color borderColor = isDark
        ? (Colors.white12 ?? Colors.white)
        : (Colors.black12 ?? Colors.black);
    final Color iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 24),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildVariantB(theme, isDark, cardColor, borderColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardWrapper(
      bool isDark,
      Color cardColor,
      Color borderColor,
      Widget child,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  static const _questionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard Variable',
  );
  static const _answerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard Variable',
    height: 1.55,
  );

  /// B: 최대 높이 애니메이션 (AnimatedSize로 부드럽게 채워짐)
  Widget _buildVariantB(
      ThemeData theme,
      bool isDark,
      Color cardColor,
      Color borderColor,
      ) {
    return ListView.builder(
      itemCount: _faqItems.length,
      itemBuilder: (context, index) {
        final item = _faqItems[index];
        return _cardWrapper(
          isDark,
          cardColor,
          borderColor,
          _FaqExpandableCardB(
            item: item,
            questionStyle: _questionStyle.copyWith(
              color: theme.textTheme.titleMedium?.color,
            ),
            answerStyle: _answerStyle.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
            ),
            onToggle: () => setState(() {}),
          ),
        );
      },
    );
  }
}

/// B: AnimatedSize만 사용 (높이만 부드럽게)
class _FaqExpandableCardB extends StatelessWidget {
  final FAQItem item;
  final TextStyle questionStyle;
  final TextStyle answerStyle;
  final VoidCallback onToggle;

  const _FaqExpandableCardB({
    required this.item,
    required this.questionStyle,
    required this.answerStyle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            item.isExpanded = !item.isExpanded;
            onToggle();
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(item.question, style: questionStyle)),
                AnimatedRotation(
                  turns: item.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: item.isExpanded
              ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(item.answer, style: answerStyle),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
