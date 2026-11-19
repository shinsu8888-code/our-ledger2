import 'package:cloud_firestore/cloud_firestore.dart';

/// 구성원(나/배우자) 프로필 — 이름과 월급
class MemberProfile {
  final String name;
  final int monthlySalary;

  const MemberProfile({required this.name, required this.monthlySalary});

  factory MemberProfile.fromMap(Map<dynamic, dynamic> m) => MemberProfile(
        name: (m['name'] as String?) ?? '이름 없음',
        monthlySalary: (m['monthlySalary'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'name': name, 'monthlySalary': monthlySalary};
}

/// 가계부 공유 단위(하우스홀드). 초대코드로 배우자를 초대한다.
class Household {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members; // uid 목록
  final Map<String, MemberProfile> profiles; // uid -> 프로필(이름/월급)

  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.profiles,
  });

  factory Household.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawMembers = (d['members'] as List?) ?? const [];
    final rawProfiles = (d['memberProfiles'] as Map?) ?? const {};
    return Household(
      id: doc.id,
      name: (d['name'] as String?) ?? '우리집 가계부',
      inviteCode: (d['inviteCode'] as String?) ?? '',
      members: rawMembers.map((e) => e.toString()).toList(),
      profiles: rawProfiles.map(
        (k, v) => MapEntry(k.toString(),
            MemberProfile.fromMap((v as Map?) ?? const {})),
      ),
    );
  }

  MemberProfile profileOf(String uid) =>
      profiles[uid] ?? const MemberProfile(name: '알 수 없음', monthlySalary: 0);

  /// 상대방(배우자) uid — 멤버가 1명이면 null
  String? partnerUidOf(String myUid) {
    for (final m in members) {
      if (m != myUid) return m;
    }
    return null;
  }
}
