import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../component/theme/app_border_radius.dart';
import '../../../../model/setting/past_plan_snapshot.dart';
import '../../../../repository/past_plan_repository.dart';
import 'past_plan_detail_page.dart';

/// 설정 > 지난 플랜 돌아보기 목록 화면
class PastPlansListPage extends StatefulWidget {
  const PastPlansListPage({super.key});

  @override
  State<PastPlansListPage> createState() => _PastPlansListPageState();
}

class _PastPlansListPageState extends State<PastPlansListPage> {
  final PastPlanRepository _repo = PastPlanRepository();
  List<PastPlanSnapshot> _list = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var list = _repo.load();
    if (list.isEmpty) {
      await _repo.add(PastPlanSnapshot.demoWorldTravel());
      list = _repo.load();
    }
    if (mounted) {
      setState(() {
        _list = list;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '지난 플랜 돌아보기',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_edu,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '완료한 플랜이 없어요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '플랜을 완료하면 여기에 기록돼요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                itemCount: _list.length,
                itemBuilder: (context, index) {
                  final snapshot = _list[index];
                  final completedStr = DateFormat(
                    'yyyy.MM.dd',
                  ).format(snapshot.completedAt);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.card,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppBorderRadius.card,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PastPlanDetailPage(snapshot: snapshot),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snapshot.planName.isEmpty
                                          ? '플랜'
                                          : snapshot.planName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${snapshot.daysTaken}일 · $completedStr 완료',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
