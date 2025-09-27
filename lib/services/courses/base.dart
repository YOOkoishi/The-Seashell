import 'dart:async';
import 'package:flutter/foundation.dart';

import '/types/courses.dart';
import '/services/base.dart';

abstract class BaseCoursesService extends BaseService {
  static const int heartbeatInterval = 300;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatTime;

  // Account Methods

  Future<void> doLogin();

  Future<void> doLogout();

  Future<bool> doSendHeartbeat();

  Future<UserInfo> getUserInfo();

  // Data Methods

  Future<List<CourseGradeItem>> getGrades();

  Future<List<ClassItem>> getCurriculum(TermInfo termInfo);

  Future<List<ClassPeriod>> getCoursePeriods(TermInfo termInfo);

  Future<List<CalendarDay>> getCalendarDays(TermInfo termInfo);

  DateTime? getLastHeartbeatTime() => _lastHeartbeatTime;

  Future<List<CourseInfo>> getSelectedCourses(TermInfo termInfo, [String? tab]);

  Future<List<CourseInfo>> getSelectableCourses(TermInfo termInfo, String tab);

  Future<List<CourseTab>> getCourseTabs(TermInfo termInfo);

  Future<List<TermInfo>> getTerms();

  Future<List<CourseInfo>> getCourseDetail(
    TermInfo termInfo,
    CourseInfo courseInfo,
  );

  Future<bool> sendCourseSelection(TermInfo termInfo, CourseInfo courseInfo);

  @override
  Future<void> login() async {
    await doLogin();
    if (isOnline) {
      if (kDebugMode) {
        print('Courses service login called at base class');
      }
      startHeartbeat();
    }
  }

  @override
  Future<void> logout() async {
    stopHeartbeat();
    if (kDebugMode) {
      print('Courses service logout called at base class');
    }
    await doLogout();
  }

  void startHeartbeat() {
    stopHeartbeat();
    sendHeartbeat();

    _heartbeatTimer = Timer.periodic(
      Duration(seconds: heartbeatInterval),
      (timer) => sendHeartbeat(),
    );
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> sendHeartbeat() async {
    try {
      if (isOnline) {
        final success = await doSendHeartbeat();
        if (success) {
          _lastHeartbeatTime = DateTime.now();
        }
        if (kDebugMode) {
          print('Course service heartbeat sent, success: $success');
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  // Course Selection State Methods

  CourseSelectionState getCourseSelectionState();

  void updateCourseSelectionState(CourseSelectionState state);

  void addCourseToSelection(CourseInfo course);

  void removeCourseFromSelection(String courseId, [String? classId]);

  void setSelectionTermInfo(TermInfo termInfo);

  void clearCourseSelection();
}
