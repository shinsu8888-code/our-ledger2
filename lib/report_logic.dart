import '../models/transaction_entry.dart';

/// 카테고리별 집계 결과
class CatStat {
  final String name;
  int total = 0; // 금액 합계
  int count = 0; // 사용 빈도(횟수)
  CatStat(this.name);
}

/// 월간 보고서 집계
class MonthlyReport {
  final List<TxEntry> monthTxs; // 해당 월 거래(필터 적용 후)
  final int totalIncome;
  final int totalExpense;
  final Map<String, CatStat> expenseByCat; // 카테고리별 지출
  final Map<String, CatStat> incomeByCat; // 카테고리별 수입
  final Map<int, int> dailyExpense; // 일 -> 지출 합계
  final int myExpense;
  final int partnerExpense;
  final int myIncome;
  final int partnerIncome;

  const MonthlyReport({
    required this.monthTxs,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCat,
    required this.incomeByCat,
    required this.dailyExpense,
    required this.myExpense,
    required this.partnerExpense,
    required this.myIncome,
    required this.partnerIncome,
  });

  int get balance => totalIncome - totalExpense;

  /// 수입 대비 지출률 (%)
  double get expenseRatio =>
      totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0;
}

/// 같은 달(연/월 기준) 거래만 필터
List<TxEntry> filterMonth(List<TxEntry> txs, DateTime month) {
  return txs
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();
}

MonthlyReport buildReport({
  required List<TxEntry> monthTxs,
  required String myUid,
  String? partnerUid,
  bool onlyMine = false, // false = 부부 통합
}) {
  var list = monthTxs;
  if (onlyMine) {
    list = list.where((t) => t.ownerUid == myUid).toList();
  }

  var totalIncome = 0, totalExpense = 0;
  final expenseByCat = <String, CatStat>{};
  final incomeByCat = <String, CatStat>{};
  final dailyExpense = <int, int>{};
  var myExpense = 0, partnerExpense = 0, myIncome = 0, partnerIncome = 0;

  for (final t in list) {
    if (t.isIncome) {
      totalIncome += t.amount;
      incomeByCat.putIfAbsent(t.category, () => CatStat(t.category)).total += t.amount;
      incomeByCat[t.category]!.count += 1;
      if (t.ownerUid == myUid) {
        myIncome += t.amount;
      } else {
        partnerIncome += t.amount;
      }
    } else {
      totalExpense += t.amount;
      expenseByCat.putIfAbsent(t.category, () => CatStat(t.category)).total += t.amount;
      expenseByCat[t.category]!.count += 1;
      dailyExpense.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
      if (t.ownerUid == myUid) {
        myExpense += t.amount;
      } else if (partnerUid != null && t.ownerUid == partnerUid) {
        partnerExpense += t.amount;
      }
    }
  }

  return MonthlyReport(
    monthTxs: list,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    expenseByCat: expenseByCat,
    incomeByCat: incomeByCat,
    dailyExpense: dailyExpense,
    myExpense: myExpense,
    partnerExpense: partnerExpense,
    myIncome: myIncome,
    partnerIncome: partnerIncome,
  );
}
