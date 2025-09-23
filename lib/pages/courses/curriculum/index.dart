import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '/services/provider.dart';
import '/types/courses.dart';
import '/types/preferences.dart';
import '/utils/app_bar.dart';
import 'common.dart';
import 'table.dart';

class MajorPeriodInfo {
  final int id;
  final String name;
  final String startTime;
  final String endTime;

  MajorPeriodInfo(this.id, this.name, this.startTime, this.endTime);
}

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage>
    with TickerProviderStateMixin {
  final ServiceProvider _serviceProvider = ServiceProvider.instance;

  CurriculumIntegratedData? _curriculumData;
  String? _errorMessage;
  int _currentWeek = 1;
  bool _isLoading = false;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  static const int maxWeeks = 50;

  @override
  void initState() {
    super.initState();
    _serviceProvider.addListener(_onServiceStatusChanged);

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.linear),
    );

    _loadCurriculumFromCacheOrService();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _serviceProvider.removeListener(_onServiceStatusChanged);
    super.dispose();
  }

  CurriculumSettings getSettings() {
    final cached = _serviceProvider.storeService.getPref<CurriculumSettings>(
      "curriculum",
      CurriculumSettings.fromJson,
    );
    return cached ?? CurriculumSettings.defaultSettings;
  }

  void saveSettings(CurriculumSettings settings) {
    _serviceProvider.storeService.putPref<CurriculumSettings>(
      "curriculum",
      settings,
    );
  }

  bool get isActivated => getSettings().activated;

  void setActivated(bool activated) {
    final settings = getSettings();
    final newSettings = CurriculumSettings(
      weekendMode: settings.weekendMode,
      tableSize: settings.tableSize,
      activated: activated,
    );
    saveSettings(newSettings);
  }

  void _onServiceStatusChanged() {
    if (mounted) {
      setState(() {
        _loadCurriculumFromCacheOrService();
      });
    }
  }

  Future<void> _loadCurriculumFromCacheOrService() async {
    final cachedData = _serviceProvider.storeService
        .getCache<CurriculumIntegratedData>(
          "curriculum_data",
          CurriculumIntegratedData.fromJson,
        );

    if (cachedData.isNotEmpty) {
      if (mounted) {
        setState(() {
          _curriculumData = cachedData.value;
          _errorMessage = null;
          _adjustCurrentWeek();
        });
        _fadeAnimationController.forward();
      }
      return;
    }

    final service = _serviceProvider.coursesService;
    if (!service.isOnline) {
      if (mounted) {
        setState(() {
          _curriculumData = null;
          _errorMessage = null;
        });
      }
      return;
    }
  }

  Future<void> _loadCurriculumForTerm(TermInfo termInfo) async {
    final service = _serviceProvider.coursesService;

    if (!service.isOnline) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final futures = await Future.wait([
        service.getCurriculum(termInfo),
        service.getCoursePeriods(termInfo),
        service.getCalendarDays(termInfo).catchError((e) => <CalendarDay>[]),
      ]);

      final classes = futures[0] as List<ClassItem>;
      final periods = futures[1] as List<ClassPeriod>;
      final calendarDays = futures[2] as List<CalendarDay>;

      final integratedData = CurriculumIntegratedData(
        currentTerm: termInfo,
        allClasses: classes,
        allPeriods: periods,
        calendarDays: calendarDays.isEmpty ? null : calendarDays,
      );

      _serviceProvider.storeService.putCache<CurriculumIntegratedData>(
        "curriculum_data",
        integratedData,
      );

      setActivated(true);

      if (mounted) {
        setState(() {
          _curriculumData = integratedData;
          _isLoading = false;
          _adjustCurrentWeek();
        });
        _fadeAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageAppBar(
        title: '课程表',
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.settings),
              tooltip: '课程表设置',
            ),
          ),
        ],
      ),
      body: _buildBody(),
      endDrawer: _buildSettingsDrawer(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败: $_errorMessage',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshCurriculumData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final cachedData = _serviceProvider.storeService
        .getCache<CurriculumIntegratedData>(
          "curriculum_data",
          CurriculumIntegratedData.fromJson,
        );

    if (cachedData.isNotEmpty) {
      final data = cachedData.value!;
      // Check activated status from settings
      if (isActivated) {
        if (mounted && _curriculumData != data) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _curriculumData = data;
              _adjustCurrentWeek();
            });
          });
        }
        return _buildCurriculumView();
      } else {
        // not activated
        return _buildSelectionView(cachedData);
      }
    } else {
      if (!_serviceProvider.coursesService.isOnline) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.login, size: 64, color: Colors.grey),
                ),
                onPressed: () => context.router.pushPath('/courses/account'),
              ),
              const SizedBox(height: 16),
              const Text(
                '请先登录',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return _buildSelectionView(null);
    }
  }

  Widget _buildSelectionView(cachedData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool shouldUseDoubleColumn = constraints.maxWidth > 1000;

          if (shouldUseDoubleColumn &&
              cachedData != null &&
              cachedData.isNotEmpty) {
            // Two column layout
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChooseLatestCard(
                        isLoggedIn: _serviceProvider.coursesService.isOnline,
                        getTerms: () =>
                            _serviceProvider.coursesService.getTerms(),
                        onTermSelected: _loadCurriculumForTerm,
                        useFlexLayout: true,
                        isLoading: _isLoading,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChooseCacheCard(
                        cachedData: cachedData,
                        onSubmit: _activateAndViewCachedData,
                        useFlexLayout: true,
                        isLoading: _isLoading,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Single column layout
            return Column(
              children: [
                ChooseLatestCard(
                  isLoggedIn: _serviceProvider.coursesService.isOnline,
                  getTerms: () => _serviceProvider.coursesService.getTerms(),
                  onTermSelected: _loadCurriculumForTerm,
                  isLoading: _isLoading,
                ),
                if (cachedData != null && cachedData.isNotEmpty)
                  ChooseCacheCard(
                    cachedData: cachedData,
                    onSubmit: _activateAndViewCachedData,
                    isLoading: _isLoading,
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  void _activateAndViewCachedData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final cachedData = _serviceProvider.storeService
        .getCache<CurriculumIntegratedData>(
          "curriculum_data",
          CurriculumIntegratedData.fromJson,
        );

    if (cachedData.isNotEmpty) {
      final data = cachedData.value!;

      setActivated(true);

      if (mounted) {
        setState(() {
          _curriculumData = data;
          _isLoading = false;
          _adjustCurrentWeek();
        });
        _fadeAnimationController.forward();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCurriculumView() {
    if (_curriculumData == null || _curriculumData!.allClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无课程数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_curriculumData != null)
              Text(
                '当前查看：${_curriculumData!.currentTerm.year}学年 第${_curriculumData!.currentTerm.season}学期',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearCacheAndSelectTerm,
              child: const Text('重新选择学期'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildWeekSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onPanEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx.abs() > 400) {
                  if (details.velocity.pixelsPerSecond.dx > 0) {
                    // Slide from left
                    if (_currentWeek > 1) {
                      _changeWeek(-1);
                    }
                  } else {
                    // Slide from right
                    if (_currentWeek < _getMaxValidWeek()) {
                      _changeWeek(1);
                    }
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _fadeAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCurriculumTable(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCurriculumData() async {
    _serviceProvider.storeService.removeCache("curriculum_data");
    await _loadCurriculumFromCacheOrService();
  }

  Future<void> _clearCacheAndSelectTerm() async {
    _serviceProvider.storeService.removeCache("curriculum_data");
    if (mounted) {
      setState(() {
        _curriculumData = null;
        _errorMessage = null;
      });
    }
  }

  Widget _buildWeekSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _currentWeek > 1 ? () => _changeWeek(-1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                '第 $_currentWeek 周',
                key: ValueKey(_currentWeek),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Tooltip(
          message: _currentWeek >= _getMaxValidWeek() ? '已经到最大周次了~' : '',
          child: IconButton(
            onPressed: _currentWeek < _getMaxValidWeek()
                ? () => _changeWeek(1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  void _changeWeek(int delta) {
    final maxValidWeek = _getMaxValidWeek();
    final newWeek = (_currentWeek + delta).clamp(1, maxValidWeek);

    if (newWeek == _currentWeek) return;

    _fadeAnimationController.reset();
    setState(() {
      _currentWeek = newWeek;
    });
    _fadeAnimationController.forward();
  }

  void _adjustCurrentWeek() {
    final maxValidWeek = _getMaxValidWeek();
    if (_currentWeek > maxValidWeek) {
      _currentWeek = maxValidWeek;
    }

    // 尝试自动切换到当前日期所在的周次
    final todayWeek = _getCurrentDateWeek();
    if (todayWeek != null && todayWeek >= 1 && todayWeek <= maxValidWeek) {
      _currentWeek = todayWeek;
    }
  }

  // 获取当前日期对应的周次
  int? _getCurrentDateWeek() {
    if (_curriculumData?.calendarDays == null ||
        _curriculumData!.calendarDays!.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final calendarDay in _curriculumData!.calendarDays!) {
      final dayDate = DateTime(
        calendarDay.year,
        calendarDay.month,
        calendarDay.day,
      );
      if (dayDate.year == today.year &&
          dayDate.month == today.month &&
          dayDate.day == today.day) {
        return calendarDay.weekIndex;
      }
    }
    return null;
  }

  int _getMaxValidWeek() {
    int maxWeekWithClasses = 0;

    if (_curriculumData != null && _curriculumData!.allClasses.isNotEmpty) {
      for (final classItem in _curriculumData!.allClasses) {
        if (classItem.weeks.isNotEmpty) {
          final maxWeekInClass = classItem.weeks.reduce(
            (a, b) => a > b ? a : b,
          );
          if (maxWeekInClass > maxWeekWithClasses) {
            maxWeekWithClasses = maxWeekInClass;
          }
        }
      }
    }

    int maxWeekFromCalendar = 0;
    if (_curriculumData?.calendarDays != null &&
        _curriculumData!.calendarDays!.isNotEmpty) {
      for (final calendarDay in _curriculumData!.calendarDays!) {
        if (calendarDay.weekIndex > 0 && calendarDay.weekIndex < 99) {
          if (calendarDay.weekIndex > maxWeekFromCalendar) {
            maxWeekFromCalendar = calendarDay.weekIndex;
          }
        }
      }
    }

    final combinedMax = maxWeekWithClasses > maxWeekFromCalendar
        ? maxWeekWithClasses
        : maxWeekFromCalendar;

    final validMax = combinedMax > 0 ? combinedMax : 1;
    return validMax > maxWeeks ? maxWeeks : validMax;
  }

  Map<int, int> _getWeekDates() {
    if (_curriculumData?.calendarDays == null ||
        _curriculumData!.calendarDays!.isEmpty) {
      return {};
    }

    final weekDays = <int, int>{};
    for (final calendarDay in _curriculumData!.calendarDays!) {
      if (calendarDay.weekIndex == _currentWeek) {
        weekDays[calendarDay.weekday] = calendarDay.day;
      }
    }
    return weekDays;
  }

  Widget _buildCurriculumTable() {
    if (_curriculumData == null || _curriculumData!.allPeriods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              '课时数据未加载',
              style: TextStyle(fontSize: 18, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text(
              '无法显示课表时间信息',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshCurriculumData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          final settings = getSettings();
          final weekDates = _getWeekDates();

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: CurriculumTable(
              curriculumData: _curriculumData!,
              availableWidth: constraints.maxWidth,
              settings: settings,
              weekDates: weekDates,
              currentWeek: _currentWeek,
            ),
          );
        } catch (e) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '课表构建失败: $e',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshCurriculumData,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSettingsDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: const Row(
              children: [
                Icon(Icons.settings, size: 24),
                SizedBox(width: 8),
                Text(
                  '课程表设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_curriculumData != null) ...[
            _buildCurriculumInfo(),
            const Divider(),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _buildWeekendDisplaySetting(),
                const SizedBox(height: 8),
                _buildTableSizeSetting(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumInfo() {
    final cachedData = _serviceProvider.storeService
        .getCache<CurriculumIntegratedData>(
          "curriculum_data",
          CurriculumIntegratedData.fromJson,
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, size: 18),
              const SizedBox(width: 4),
              Text(
                '${_curriculumData!.currentTerm.year}学年 第${_curriculumData!.currentTerm.season}学期',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (cachedData.isNotEmpty)
            Text(
              '缓存时间：${formatCacheTime(cachedData)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deactivateCurrentData,
              icon: const Icon(Icons.cached),
              label: const Text('切换学期或更新'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deactivateCurrentData() {
    if (_curriculumData != null) {
      // Set activated to false in settings
      setActivated(false);

      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }

      Navigator.of(context).pop();
    }
  }

  Widget _buildWeekendDisplaySetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '显示周末',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<WeekendDisplayMode>(
                initialValue: getSettings().weekendMode,
                items: WeekendDisplayMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode.displayName),
                  );
                }).toList(),
                onChanged: (WeekendDisplayMode? newMode) {
                  if (newMode != null) {
                    final currentSettings = getSettings();
                    saveSettings(currentSettings..weekendMode = newMode);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSizeSetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '表格尺寸',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<TableSize>(
                initialValue: getSettings().tableSize,
                items: TableSize.values.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size.displayName),
                  );
                }).toList(),
                onChanged: (TableSize? newSize) {
                  if (newSize != null) {
                    final currentSettings = getSettings();
                    saveSettings(currentSettings..tableSize = newSize);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
