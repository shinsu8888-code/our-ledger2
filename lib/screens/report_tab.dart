import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/household.dart';
import '../models/transaction_entry.dart';
import '../report_logic.dart';
import 'ledger_tab.dart' show Scope;

/// 탭2: 월간 보고서
/// - 카테고리별 지출 비중(도넛) + 빈도(횟수) 랭킹
/// - 일별 지출(막대) = 한 달 사용 빈도 패턴
/// - 나 vs 배우자 지출 비교(막대)
/// - 수입 대비 지출률
class ReportTab extends StatefulWidget {
  final Household household;
  final String myUid;
  final List<TxEntry> allTxs;

  const ReportTab({
    super.key,
    required this.household,
    required this.myUid,
    required this.allTxs,
  });

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Scope _scope = Scope.both;

  @override
  Widget build(BuildContext context) {
    final partnerUid = widget.household.partnerUidOf(widget.myUid);
    final monthTxs = filterMonth(widget.allTxs, _month);
    final report = buildReport(
      monthTxs: monthTxs,
      myUid: widget.myUid,
      partnerUid: partnerUid,
      onlyMine: _scope == Scope.mine,
    );
    final fmt = NumberFormat('#,###');

    // 카테고리 정렬 (금액 내림차순)
    final cats = report.expenseByCat.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final totalExpense = report.totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('yyyy년 M월', 'ko').format(_month)} 보고서'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 월 선택 + 범위
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1)),
              ),
              Expanded(
                child: SegmentedButton<Scope>(
                  segments: const [
                    ButtonSegment(value: Scope.both, label: Text('통합')),
                    ButtonSegment(value: Scope.mine, label: Text('나')),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (s) => setState(() => _scope = s.first),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _kv('총 수입', '${fmt.format(report.totalIncome)} 원', Colors.green),
                      _kv('총 지출', '${fmt.format(report.totalExpense)} 원', Colors.red),
                      _kv('잔액', '${fmt.format(report.balance)} 원',
                          report.balance >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                  const Divider(height: 24),
                  // 지출률 게이지
                  Text(
                    '수입 대비 지출률 ${report.expenseRatio.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (report.expenseRatio / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                    color: report.expenseRatio > 90
                        ? Colors.red
                        : report.expenseRatio > 70
                            ? Colors.orange
                            : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 카테고리별 지출 도넛
          _title('📊 카테고리별 지출 비중'),
          if (cats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('이 달의 지출 기록이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            )
          else
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: [
                    for (var i = 0; i < cats.length && i < 8; i++)
                      PieChartSectionData(
                        value: cats[i].total.toDouble(),
                        title: '${(cats[i].total / totalExpense * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        radius: 60,
                        color: categoryOf(cats[i].name, false).color,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final c in cats.take(8))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 10, height: 10,
                        color: categoryOf(c.name, false).color),
                    const SizedBox(width: 4),
                    Text(c.name,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 카테고리별 빈도 랭킹
          _title('🏆 카테고리별 사용 순위 (금액 · 횟수)'),
          ...cats.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(categoryOf(c.name, false).icon,
                    color: categoryOf(c.name, false).color),
                title: Text(c.name),
                subtitle: Text('${fmt.format(c.total)} 원 · ${c.count}회 사용'),
                trailing: Text(
                    '${(c.total / (totalExpense == 0 ? 1 : totalExpense) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
          const SizedBox(height: 24),

          // 일별 지출 패턴
          _title('📅 일별 지출 패턴 (한 달 사용 빈도)'),
          if (report.dailyExpense.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('지출 기록이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: report.dailyExpense.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() *
                      1.2,
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (final e in report.dailyExpense.entries)
                      BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            width: 10,
                            borderRadius: BorderRadius.circular(3),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          Text(
            '지출한 날: ${report.dailyExpense.length}일 / 이 달 기록 ${report.monthTxs.where((t) => !t.isIncome).length}건',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // 나 vs 배우자 비교 (통합 모드에서만)
          if (_scope == Scope.both && partnerUid != null) ...[
            _title('👫 나 vs 배우자 비교'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _personBar(
                        widget.household.profileOf(widget.myUid).name,
                        report.myIncome,
                        report.myExpense),
                    const SizedBox(height: 12),
                    _personBar(
                        widget.household.profileOf(partnerUid).name,
                        report.partnerIncome,
                        report.partnerExpense),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('부부 합계 수입',
                            style: TextStyle(fontSize: 13)),
                        Text('${fmt.format(report.totalIncome)} 원',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('부부 합계 지출',
                            style: TextStyle(fontSize: 13)),
                        Text('${fmt.format(report.totalExpense)} 원',
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _personBar(String name, int income, int expense) {
    final maxVal = (income > expense ? income : expense)
        .clamp(1, 1 << 62)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _bar('수입', income, maxVal, Colors.green),
        const SizedBox(height: 4),
        _bar('지출', expense, maxVal, Colors.red),
      ],
    );
  }

  Widget _bar(String label, int value, double max, Color color) {
    final fmt = NumberFormat('#,###');
    return Row(
      children: [
        SizedBox(
            width: 32,
            child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
          child: LinearProgressIndicator(
            value: value / max,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: color,
            backgroundColor: color.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: Text('${fmt.format(value)} 원',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _kv(String k, String v, Color c) => Column(
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(v,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: c)),
        ],
      );
}
