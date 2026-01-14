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
      question: '월급이 일정하지 않아요! 이 경우엔 어떻게 월 수입을 입력하나요?',
      answer:
          '월급이 들쭉날쭉한 프리랜서, 일용직, 자영업자 분들은 최근 3~6개월간의 수입 평균을 입력하는 걸 추천드려요 🙂\n\n👉 평균치를 기준으로 계획을 세우면 더 현실적인 플랜 설정이 가능해요!',
    ),
    FAQItem(
      question: '적금이나 청약도 고정 지출에 포함되나요?',
      answer:
          '❌ 아니요! 적금, 청약, 투자 등은 **고정 지출이 아닌 \'저축 항목\'**입니다.\n\n👉 고정 지출에는 월세, 통신비, 보험료처럼 매달 자동으로 나가는 소비성 지출만 입력해주세요.',
    ),
    FAQItem(
      question: '목표 금액은 꼭 있어야 하나요?',
      answer:
          '물론이죠! 🎯 목표 금액이 있어야 내가 얼마를 아끼고, 얼마나 모아야 하는지 계산할 수 있어요.\n\n👉 아직 명확한 목표가 없다면, 추천 금액 중에서 선택해도 괜찮아요. (100만, 300만, 500만... 등)',
    ),
    FAQItem(
      question: '자동 등록 서비스는 뭔가요?',
      answer:
          '사용자가 소비를 미기록한 날에도, 미리 설정해둔 평일/주말 예산 기준으로 소비를 자동 기록해주는 기능이에요.\n\n👉 "바빠서 기록 못했어요😥" → "자동으로 입력돼 있어서 놓치지 않았어요!"\n\n단, 설정한 항목에만 적용돼요. 자동 입력은 다음 접속 시 언제든 수정 가능해요!',
    ),
    FAQItem(
      question: '계획을 수정하고 싶으면 어떻게 하나요?',
      answer:
          '언제든지 마이페이지에서 수정 가능해요!\n\n👉 수입, 고정 지출, 목표 금액, 생활비, 자동 등록 항목 전부 다 다시 설정할 수 있어요.\n\n변경 즉시 앱에 반영되고, 목표 달성일도 자동 재계산된답니다 😊',
    ),
    FAQItem(
      question: '하루 소비 한도 금액이 뭔가요?',
      answer:
          '하루 소비 한도는 내가 설정한 **한 달 생활비(변동 소비 예산)**를 기준으로\n\n📅 30일 또는 31일로 나눈 일일 평균 지출 가능 금액이에요.\n\n예: 한 달 생활비가 60만 원이면 → 하루 소비 한도는 약 20,000원!\n\n👉 이 한도는 앱이 내 소비 패턴을 분석하고, 목표 달성 날짜를 계산하는 데 기준이 돼요 😊',
    ),
    FAQItem(
      question: '하루 소비 한도보다 더 쓰거나, 덜 쓰면 어떻게 돼요?',
      answer:
          '🎯 이 앱의 핵심 기능이에요!\n\n앱은 매일의 소비가 하루 한도보다 초과/절약되었는지 실시간으로 체크하고,\n그 차이를 **시간(초 단위)**로 바꿔서 목표 도달 시점을 앞당기거나 늦춰줘요.\n\n예시\n✅ 오늘 절약: 3,000원 → 목표 달성 시각 4시간 당겨짐\n❌ 오늘 초과: 4,000원 → 목표 달성 시각 5시간 늦어짐\n\n👉 이런 변화는 홈 화면의 타이머에도 즉시 반영돼요.\n👀 내가 얼마나 잘 아끼고 있는지 실시간으로 확인할 수 있죠!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '자주 묻는 질문',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '궁금한 점이 있으시면 아래 질문을 탭해보세요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _faqItems.length,
                  itemBuilder: (context, index) {
                    final item = _faqItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.7)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: item.isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            item.isExpanded = expanded;
                          });
                        },
                        title: Text(
                          item.question,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard Variable',
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        trailing: Icon(
                          item.isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Text(
                              item.answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.8),
                                fontFamily: 'Pretendard Variable',
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
