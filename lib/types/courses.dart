import 'package:json_annotation/json_annotation.dart';
import 'base.dart';

part 'courses.g.dart';

@JsonSerializable()
class UserInfo extends BaseDataClass {
  final String userName;
  final String userNameAlt;
  final String userSchool;
  final String userSchoolAlt;
  final String userId;

  const UserInfo({
    required this.userName,
    required this.userNameAlt,
    required this.userSchool,
    required this.userSchoolAlt,
    required this.userId,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'userName': userName,
      'userNameAlt': userNameAlt,
      'userSchool': userSchool,
      'userSchoolAlt': userSchoolAlt,
      'userId': userId,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class UserLoginIntegratedData extends BaseDataClass {
  final UserInfo? user;
  final String? method;
  final String? cookie;
  final String? lastSmsPhone;

  const UserLoginIntegratedData({
    this.user,
    this.method,
    this.cookie,
    this.lastSmsPhone,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'user': user,
      'method': method,
      'cookie': cookie,
      'lastSmsPhone': lastSmsPhone,
    };
  }

  factory UserLoginIntegratedData.fromJson(Map<String, dynamic> json) =>
      _$UserLoginIntegratedDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserLoginIntegratedDataToJson(this);
}

@JsonSerializable()
class CourseGradeItem extends BaseDataClass {
  final String courseId;
  final String courseName;
  final String? courseNameAlt;
  final String termId;
  final String termName;
  final String termNameAlt;
  final String type;
  final String category;
  final String? schoolName;
  final String? schoolNameAlt;
  final String? makeupStatus;
  final String? makeupStatusAlt;
  final String? examType;
  final double hours;
  final double credit;
  final double score;

  const CourseGradeItem({
    required this.courseId,
    required this.courseName,
    this.courseNameAlt,
    required this.termId,
    required this.termName,
    required this.termNameAlt,
    required this.type,
    required this.category,
    this.schoolName,
    this.schoolNameAlt,
    this.makeupStatus,
    this.makeupStatusAlt,
    this.examType,
    required this.hours,
    required this.credit,
    required this.score,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {'courseId': courseId, 'termId': termId};
  }

  factory CourseGradeItem.fromJson(Map<String, dynamic> json) =>
      _$CourseGradeItemFromJson(json);
  Map<String, dynamic> toJson() => _$CourseGradeItemToJson(this);
}

@JsonSerializable()
class ClassItem extends BaseDataClass {
  final int day; // 星期几 (1-7)
  final int period; // 大节节次
  final List<int> weeks; // 周次
  final String weeksText; // 周次文本描述
  final String className; // 课程名称
  final String? classNameAlt; // 课程名称（英文）
  final String teacherName; // 教师名称
  final String? teacherNameAlt; // 教师名称（英文）
  final String locationName; // 地点名称
  final String? locationNameAlt; // 地点名称（英文）
  final String periodName; // 课节文字描述
  final String? periodNameAlt; // 课节文字描述（英文）
  final int? colorId; // 背景颜色编号

  const ClassItem({
    required this.day,
    required this.period,
    required this.weeks,
    required this.weeksText,
    required this.className,
    this.classNameAlt,
    required this.teacherName,
    this.teacherNameAlt,
    required this.locationName,
    this.locationNameAlt,
    required this.periodName,
    this.periodNameAlt,
    this.colorId,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'day': day,
      'period': period,
      'className': className,
      'teacherName': teacherName,
    };
  }

  factory ClassItem.fromJson(Map<String, dynamic> json) =>
      _$ClassItemFromJson(json);
  Map<String, dynamic> toJson() => _$ClassItemToJson(this);
}

@JsonSerializable()
class ClassPeriod extends BaseDataClass {
  final String termYear; // 学年
  final int termSeason; // 学期
  final int majorId; // 大节编号
  final int minorId; // 小节编号
  final String majorName; // 大节名称
  final String minorName; // 小节名称
  final String? majorStartTime; // 大节开始时间
  final String? majorEndTime; // 大节结束时间
  final String minorStartTime; // 小节开始时间
  final String minorEndTime; // 小节结束时间

  const ClassPeriod({
    required this.termYear,
    required this.termSeason,
    required this.majorId,
    required this.minorId,
    required this.majorName,
    required this.minorName,
    this.majorStartTime,
    this.majorEndTime,
    required this.minorStartTime,
    required this.minorEndTime,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {'termYear': termYear, 'termSeason': termSeason, 'minorId': minorId};
  }

  String get timeRange => '$minorStartTime-$minorEndTime';

  factory ClassPeriod.fromJson(Map<String, dynamic> json) =>
      _$ClassPeriodFromJson(json);
  Map<String, dynamic> toJson() => _$ClassPeriodToJson(this);
}

@JsonSerializable()
class CalendarDay extends BaseDataClass {
  final int year;
  final int month;
  final int day;
  final int weekday;
  final int weekIndex;

  const CalendarDay({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    required this.weekIndex,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'year': year,
      'month': month,
      'day': day,
      'weekday': weekday,
      'weekIndex': weekIndex,
    };
  }

  factory CalendarDay.fromJson(Map<String, dynamic> json) =>
      _$CalendarDayFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarDayToJson(this);
}

@JsonSerializable()
class TermInfo extends BaseDataClass {
  final String year; // eg. "2024-2025"
  final int season;

  const TermInfo({required this.year, required this.season});

  @override
  Map<String, dynamic> getEssentials() {
    return {'year': year, 'season': season};
  }

  factory TermInfo.fromJson(Map<String, dynamic> json) =>
      _$TermInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TermInfoToJson(this);
}

@JsonSerializable()
class CurriculumIntegratedData extends BaseDataClass {
  final TermInfo currentTerm;
  final List<ClassItem> allClasses;
  final List<ClassPeriod> allPeriods;
  final List<CalendarDay>? calendarDays;

  const CurriculumIntegratedData({
    required this.currentTerm,
    required this.allClasses,
    required this.allPeriods,
    this.calendarDays,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'currentTerm': currentTerm.getEssentials(),
      'classCount': allClasses.length,
      'periodCount': allPeriods.length,
    };
  }

  factory CurriculumIntegratedData.fromJson(Map<String, dynamic> json) =>
      _$CurriculumIntegratedDataFromJson(json);
  Map<String, dynamic> toJson() => _$CurriculumIntegratedDataToJson(this);
}

@JsonSerializable()
class CourseDetail extends BaseDataClass {
  final String classId; // 讲台代码
  final String? extraName; // 额外名称
  final String? extraNameAlt; // 额外名称英文
  final String selectionStatus; // 选课状态
  final String selectionStartTime; // 讲台选课开始时间
  final String selectionEndTime; // 讲台选课结束时间
  final int ugTotal; // 本科生容量
  final int ugReserved; // 本科生已选
  final int pgTotal; // 研究生容量
  final int pgReserved; // 研究生已选
  final int? maleTotal; // 男生容量
  final int? maleReserved; // 男生已选
  final int? femaleTotal; // 女生容量
  final int? femaleReserved; // 女生已选

  final String? detailHtml; // 详情描述HTML
  final String? detailHtmlAlt; // 详情描述HTML英文
  final String? detailTeacherId; // 教师内部ID
  final String? detailTeacherName; // 教师名称
  final String? detailTeacherNameAlt; // 教师名称英文
  final List<String>? detailSchedule; // 上课时间列表
  final List<String>? detailScheduleAlt; // 上课时间列表英文
  final String? detailClasses; // 生效班级
  final String? detailClassesAlt; // 生效班级英文
  final List<String>? detailTarget; // 面向对象列表
  final List<String>? detailTargetAlt; // 面向对象列表英文
  final String? detailExtra; // 额外信息
  final String? detailExtraAlt; // 额外信息英文

  const CourseDetail({
    required this.classId,
    this.extraName,
    this.extraNameAlt,
    this.detailHtml,
    this.detailHtmlAlt,
    this.detailTeacherId,
    this.detailTeacherName,
    this.detailTeacherNameAlt,
    this.detailSchedule,
    this.detailScheduleAlt,
    this.detailClasses,
    this.detailClassesAlt,
    this.detailTarget,
    this.detailTargetAlt,
    this.detailExtra,
    this.detailExtraAlt,
    required this.selectionStatus,
    required this.selectionStartTime,
    required this.selectionEndTime,
    required this.ugTotal,
    required this.ugReserved,
    required this.pgTotal,
    required this.pgReserved,
    this.maleTotal,
    this.maleReserved,
    this.femaleTotal,
    this.femaleReserved,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {'classId': classId};
  }

  bool get hasUg => ugTotal > 0;

  bool get hasPg => pgTotal > 0;

  bool get hasMale => (maleTotal ?? 0) > 0;

  bool get hasFemale => (femaleTotal ?? 0) > 0;

  bool get isAllFull {
    bool hasSomeCapacity = false;
    bool allCapacitiesFull = true;

    if (hasUg) {
      hasSomeCapacity = true;
      if (ugReserved < ugTotal) {
        allCapacitiesFull = false;
      }
    }

    if (hasPg) {
      hasSomeCapacity = true;
      if (pgReserved < pgTotal) {
        allCapacitiesFull = false;
      }
    }

    if (hasMale) {
      hasSomeCapacity = true;
      if ((maleReserved ?? 0) < (maleTotal ?? 0)) {
        allCapacitiesFull = false;
      }
    }

    if (hasFemale) {
      hasSomeCapacity = true;
      if ((femaleReserved ?? 0) < (femaleTotal ?? 0)) {
        allCapacitiesFull = false;
      }
    }

    return hasSomeCapacity && allCapacitiesFull;
  }

  factory CourseDetail.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailFromJson(json);
  Map<String, dynamic> toJson() => _$CourseDetailToJson(this);
}

@JsonSerializable()
class CourseInfo extends BaseDataClass {
  final String courseId; // 课程代码
  final String courseName; // 课程名称
  final String? courseNameAlt; // 课程名称英文
  final String courseType; // 课程限制类型
  final String? courseTypeAlt; // 课程限制类型英文
  final String courseCategory; // 课程类别
  final String? courseCategoryAlt; // 课程类别英文
  final String districtName; // 校区名称
  final String? districtNameAlt; // 校区名称英文
  final String schoolName; // 开课院系名称
  final String? schoolNameAlt; // 开课院系名称英文
  final String termName; // 学年学期
  final String? termNameAlt; // 学年学期英文
  final String teachingLanguage; // 授课语言
  final String? teachingLanguageAlt; // 授课语言英文
  final double credits; // 学分
  final double hours; // 学时
  final CourseDetail? classDetail; // 讲台详情
  final String? fromTabId; // 来源标签页ID

  const CourseInfo({
    required this.courseId,
    required this.courseName,
    this.courseNameAlt,
    required this.courseType,
    this.courseTypeAlt,
    required this.courseCategory,
    this.courseCategoryAlt,
    required this.districtName,
    this.districtNameAlt,
    required this.schoolName,
    this.schoolNameAlt,
    required this.termName,
    this.termNameAlt,
    required this.teachingLanguage,
    this.teachingLanguageAlt,
    required this.credits,
    required this.hours,
    this.classDetail,
    this.fromTabId,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {'courseId': courseId, 'classDetail': classDetail?.classId};
  }

  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseInfoToJson(this);
}

@JsonSerializable()
class CourseTab extends BaseDataClass {
  final String tabId; // 选课标签页代码
  final String tabName; // 标签页名称
  final String? tabNameAlt; // 标签页名称英文
  final String? selectionStartTime; // 选课开始时间
  final String? selectionEndTime; // 选课结束时间

  const CourseTab({
    required this.tabId,
    required this.tabName,
    this.tabNameAlt,
    this.selectionStartTime,
    this.selectionEndTime,
  });

  @override
  Map<String, dynamic> getEssentials() {
    return {'tabId': tabId};
  }

  factory CourseTab.fromJson(Map<String, dynamic> json) =>
      _$CourseTabFromJson(json);
  Map<String, dynamic> toJson() => _$CourseTabToJson(this);
}

@JsonSerializable()
class CourseSelectionState extends BaseDataClass {
  final TermInfo? termInfo;
  final List<CourseInfo> wantedCourses;

  const CourseSelectionState({this.termInfo, this.wantedCourses = const []});

  @override
  Map<String, dynamic> getEssentials() {
    return {
      'termInfo': termInfo?.toString(),
      'wantedCoursesCount': wantedCourses.length,
    };
  }

  CourseSelectionState addCourse(CourseInfo course) {
    if (wantedCourses.any(
      (c) =>
          c.courseId == course.courseId &&
          c.classDetail?.classId == course.classDetail?.classId,
    )) {
      // Do nothing
      return this;
    }
    return CourseSelectionState(
      termInfo: termInfo,
      wantedCourses: [...wantedCourses, course],
    );
  }

  CourseSelectionState removeCourse(String courseId, [String? classId]) {
    return CourseSelectionState(
      termInfo: termInfo,
      wantedCourses: wantedCourses
          .where(
            (c) =>
                !(c.courseId == courseId &&
                    (classId == null || c.classDetail?.classId == classId)),
          )
          .toList(),
    );
  }

  CourseSelectionState setTermInfo(TermInfo termInfo) {
    return CourseSelectionState(
      termInfo: termInfo,
      wantedCourses: wantedCourses,
    );
  }

  CourseSelectionState clear() {
    return const CourseSelectionState();
  }

  bool containsCourse(String courseId, [String? classId]) {
    return wantedCourses.any(
      (c) =>
          c.courseId == courseId &&
          (classId == null || c.classDetail?.classId == classId),
    );
  }

  factory CourseSelectionState.fromJson(Map<String, dynamic> json) =>
      _$CourseSelectionStateFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSelectionStateToJson(this);
}
