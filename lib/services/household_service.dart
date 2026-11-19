import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/household.dart';
import '../models/transaction_entry.dart';
import 'app_mode.dart';
import 'local_backend.dart';
import 'prefs_service.dart';

/// 거래 저장소 — 클라우드(Firestore) / 오프라인(내 폰) 자동 전환
class TxRepository {
  final String householdId;
  TxRepository(this.householdId);

  CollectionReference<Map<String, dynamic>> _col() => FirebaseFirestore
      .instance
      .collection('households')
      .doc(householdId)
      .collection('transactions');

  /// 전체 거래 목록 스트림 (변경 시 즉시 반영)
  Stream<List<TxEntry>> stream() {
    if (!AppMode.cloud) return LocalStore.instance.stream();
    return _col()
        .orderBy('date', descending: true)
        .limit(500)
        .snapshots()
        .map((s) => s.docs.map(TxEntry.fromDoc).toList());
  }

  Future<void> add(TxEntry e) async {
    if (!AppMode.cloud) {
      await LocalStore.instance.add(e);
      return;
    }
    await _col().add(e.toMap());
  }

  Future<void> delete(String id) async {
    if (!AppMode.cloud) {
      await LocalStore.instance.delete(id);
      return;
    }
    await _col().doc(id).delete();
  }
}

/// 인증 + 가계부(하우스홀드) 관리
class HouseholdService {
  final String uid;
  HouseholdService(this.uid);

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  /// 내가 속한 가계부 불러오기 (없으면 null — 오프라인 모드는 항상 로컬 가계부)
  Future<Household?> loadMyHousehold() async {
    if (!AppMode.cloud) return LocalStore.instance.household();
    final q = await FirebaseFirestore.instance
        .collection('households')
        .where('members', arrayContains: uid)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Household.fromDoc(q.docs.first);
  }

  /// 새 가계부 만들기 (내가 첫 멤버) — 클라우드 전용
  Future<Household> createHousehold({
    required String householdName,
    required String myName,
    required int mySalary,
  }) async {
    final code = _genCode();
    final profiles = {
      uid: {'name': myName, 'monthlySalary': mySalary},
    };

    final ref = await FirebaseFirestore.instance.collection('households').add({
      'name': householdName,
      'inviteCode': code,
      'members': [uid],
      'memberProfiles': profiles,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // 초대코드 -> 가계부 id 매핑 (배우자가 코드로 참여할 때 사용)
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'householdId': ref.id,
    });
    return Household(
      id: ref.id,
      name: householdName,
      inviteCode: code,
      members: [uid],
      profiles: {uid: MemberProfile(name: myName, monthlySalary: mySalary)},
    );
  }

  /// 초대코드로 배우자 가계부 참여하기 — 클라우드 전용
  Future<Household> joinByCode({
    required String code,
    required String myName,
    required int mySalary,
  }) async {
    final normalized = code.trim().toUpperCase();
    final inviteSnap = await FirebaseFirestore.instance
        .collection('invites')
        .doc(normalized)
        .get();
    if (!inviteSnap.exists) {
      throw '초대코드를 찾을 수 없어요. 코드를 다시 확인해 주세요.';
    }
    final hid = inviteSnap.data()!['householdId'] as String;
    final ref = FirebaseFirestore.instance.collection('households').doc(hid);

    await ref.update({
      'members': FieldValue.arrayUnion([uid]),
      'memberProfiles.$uid': {'name': myName, 'monthlySalary': mySalary},
    });
    final doc = await ref.get();
    return Household.fromDoc(doc);
  }

  /// 내 프로필(이름/월급) 수정
  Future<void> updateMyProfile({
    required Household household,
    required String name,
    required int salary,
  }) async {
    if (!AppMode.cloud) {
      Prefs.localName = name;
      Prefs.localSalary = salary;
      return;
    }
    await FirebaseFirestore.instance
        .collection('households')
        .doc(household.id)
        .update({
      'memberProfiles.$uid': {'name': name, 'monthlySalary': salary},
    });
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
