import 'package:flutter/material.dart';
import '/services/provider.dart';
import '/types/courses.dart';
import '/utils/app_bar.dart';

class GradePage extends StatefulWidget {
  const GradePage({super.key});

  @override
  State<GradePage> createState() => _GradePageState();
}

class _GradePageState extends State<GradePage> {
  final ServiceProvider _serviceProvider = ServiceProvider.instance;
  final TextEditingController _searchController = TextEditingController();

  // 原始数据和过滤后数据分离
  List<CourseGradeItem>? _allGrades; // 原始完整数据
  List<CourseGradeItem>? _filteredGrades; // 过滤后显示的数据

  bool _isLoading = false;
  String? _errorMessage;
  String _currentSearchQuery = '';

  // 选择状态管理
  Set<String> _selectedCourseIds = {}; // 存储选中课程的ID
  bool _isAllSelected = false; // 全选状态

  @override
  void initState() {
    super.initState();
    _serviceProvider.addListener(_onServiceStatusChanged);
    _loadGrades();
  }

  @override
  void dispose() {
    _serviceProvider.removeListener(_onServiceStatusChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceStatusChanged() {
    if (mounted) {
      setState(() {
        _loadGrades();
      });
    }
  }

  Future<void> _loadGrades() async {
    final service = _serviceProvider.coursesService;

    if (!service.isOnline) {
      if (mounted) {
        setState(() {
          _allGrades = null;
          _filteredGrades = null;
          _errorMessage = null;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final grades = await service.getGrades();
      if (mounted) {
        setState(() {
          _allGrades = grades;
          _filteredGrades = grades; // 初始时显示所有数据
          _isLoading = false;
          // 如果有搜索查询，重新应用搜索
          if (_currentSearchQuery.isNotEmpty) {
            _performSearch(_currentSearchQuery);
          }
        });
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

  Future<void> _refreshGrades() async {
    await _loadGrades();
  }

  void _performSearch(String query) {
    if (_allGrades == null) return;

    setState(() {
      _currentSearchQuery = query;
      if (query.isEmpty) {
        _filteredGrades = _allGrades;
      } else {
        _filteredGrades = _searchGrades(_allGrades!, query);
      }

      // 清除被筛选隐藏的课程的选择状态
      if (_filteredGrades != null) {
        final visibleCourseIds = _filteredGrades!
            .map((g) => g.courseId)
            .toSet();
        _selectedCourseIds.retainWhere(
          (courseId) => visibleCourseIds.contains(courseId),
        );

        // 更新全选状态
        _isAllSelected =
            visibleCourseIds.isNotEmpty &&
            visibleCourseIds.every((id) => _selectedCourseIds.contains(id));
      }
    });
  }

  List<CourseGradeItem> _searchGrades(
    List<CourseGradeItem> grades,
    String query,
  ) {
    final queryLower = query.toLowerCase();

    // 按优先级排序的搜索结果
    final List<CourseGradeItem> priorityResults = [];
    final Set<String> addedIds = <String>{};

    // 1. 课程名称及alt名称模糊匹配
    for (final grade in grades) {
      final courseNameMatch = grade.courseName.toLowerCase().contains(
        queryLower,
      );
      final courseNameAltMatch =
          grade.courseNameAlt?.toLowerCase().contains(queryLower) ?? false;

      if (courseNameMatch || courseNameAltMatch) {
        final id = '${grade.courseId}_${grade.termId}';
        if (!addedIds.contains(id)) {
          priorityResults.add(grade);
          addedIds.add(id);
        }
      }
    }

    // 2. 课程代码模糊匹配
    for (final grade in grades) {
      final courseIdMatch = grade.courseId.toLowerCase().contains(queryLower);

      if (courseIdMatch) {
        final id = '${grade.courseId}_${grade.termId}';
        if (!addedIds.contains(id)) {
          priorityResults.add(grade);
          addedIds.add(id);
        }
      }
    }

    // 3. 开课学院名称及alt名称模糊匹配
    for (final grade in grades) {
      final schoolNameMatch =
          grade.schoolName?.toLowerCase().contains(queryLower) ?? false;
      final schoolNameAltMatch =
          grade.schoolNameAlt?.toLowerCase().contains(queryLower) ?? false;

      if (schoolNameMatch || schoolNameAltMatch) {
        final id = '${grade.courseId}_${grade.termId}';
        if (!addedIds.contains(id)) {
          priorityResults.add(grade);
          addedIds.add(id);
        }
      }
    }

    // 4. 学期模糊匹配及alt名称模糊匹配
    for (final grade in grades) {
      final termNameMatch = grade.termName.toLowerCase().contains(queryLower);
      final termNameAltMatch = grade.termNameAlt.toLowerCase().contains(
        queryLower,
      );

      if (termNameMatch || termNameAltMatch) {
        final id = '${grade.courseId}_${grade.termId}';
        if (!addedIds.contains(id)) {
          priorityResults.add(grade);
          addedIds.add(id);
        }
      }
    }

    return priorityResults;
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  // 选择管理方法
  void _toggleSelectAll() {
    if (_filteredGrades == null) return;

    setState(() {
      if (_isAllSelected) {
        // 取消全选
        _selectedCourseIds.clear();
        _isAllSelected = false;
      } else {
        // 全选当前显示的课程
        _selectedCourseIds.clear();
        for (final grade in _filteredGrades!) {
          _selectedCourseIds.add(grade.courseId);
        }
        _isAllSelected = true;
      }
    });
  }

  void _toggleCourseSelection(String courseId) {
    setState(() {
      if (_selectedCourseIds.contains(courseId)) {
        _selectedCourseIds.remove(courseId);
      } else {
        _selectedCourseIds.add(courseId);
      }

      // 更新全选状态
      if (_filteredGrades != null) {
        final visibleCourseIds = _filteredGrades!
            .map((g) => g.courseId)
            .toSet();
        _isAllSelected =
            visibleCourseIds.isNotEmpty &&
            visibleCourseIds.every((id) => _selectedCourseIds.contains(id));
      }
    });
  }

  void _showQuickCalculation() {
    if (_selectedCourseIds.isEmpty) {
      _showCalculationDialog(
        title: '快捷计算',
        content: '请先选择需要参与计算的课程，在左侧打勾。',
        isError: true,
      );
      return;
    }

    if (_allGrades == null) return;

    // 获取选中的课程成绩
    final selectedGrades = _allGrades!
        .where((grade) => _selectedCourseIds.contains(grade.courseId))
        .toList();

    if (selectedGrades.isEmpty) {
      _showCalculationDialog(
        title: '快捷计算',
        content: '选中的课程中没有有效的成绩数据。',
        isError: true,
      );
      return;
    }

    // 计算平均成绩和加权成绩
    double totalScore = 0;
    double totalWeightedScore = 0;
    double totalCredits = 0;

    for (final grade in selectedGrades) {
      final score = grade.score.toDouble();
      final credit = grade.credit.toDouble();

      totalScore += score;
      totalWeightedScore += score * credit;
      totalCredits += credit;
    }

    final averageScore = totalScore / selectedGrades.length;
    final weightedScore = totalWeightedScore / totalCredits;

    _showCalculationDialog(
      title: '快捷计算',
      content:
          '已选择课程数：${selectedGrades.length}\n'
          '平均成绩：${averageScore.toStringAsFixed(4)}\n'
          '加权成绩：${weightedScore.toStringAsFixed(4)}',
      isError: false,
    );
  }

  void _showCalculationDialog({
    required String title,
    required String content,
    required bool isError,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: '成绩查询'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final service = _serviceProvider.coursesService;

    if (!service.isOnline) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('请先登录', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载成绩...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshGrades, child: const Text('重试')),
          ],
        ),
      );
    }

    // 如果还没有加载数据，显示无数据状态
    if (_allGrades == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无成绩数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildActionBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildTableOrEmptyState()),
        ],
      ),
    );
  }

  Widget _buildTableOrEmptyState() {
    if (_filteredGrades == null || _filteredGrades!.isEmpty) {
      if (_currentSearchQuery.isNotEmpty) {
        // 有搜索但没有结果，在表格位置显示搜索无结果
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '没有找到匹配"$_currentSearchQuery"的成绩',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearSearch,
                child: const Text('清除搜索'),
              ),
            ],
          ),
        );
      } else {
        // 没有搜索但也没有数据
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '暂无成绩数据',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
    }

    return _buildResponsiveTable();
  }

  Widget _buildActionBar() {
    final service = _serviceProvider.coursesService;

    return Row(
      children: [
        // 搜索框
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索课程名称、代码、学院或学期...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _currentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: _clearSearch,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 刷新按钮
        ElevatedButton.icon(
          onPressed: (service.isOnline && !_isLoading) ? _refreshGrades : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(_isLoading ? '刷新中...' : '刷新'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 40),
          ),
        ),
        const SizedBox(width: 12),
        // 快捷计算按钮
        ElevatedButton.icon(
          onPressed: _showQuickCalculation,
          icon: const Icon(Icons.calculate, size: 18),
          label: const Text('快捷计算'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 40),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // 定义列的配置
        final columnConfig = [
          {'name': '', 'minWidth': 50.0, 'flex': 0, 'isNumeric': false},
          {'name': '学期', 'minWidth': 80.0, 'flex': 2, 'isNumeric': false},
          {'name': '开课院系', 'minWidth': 80.0, 'flex': 2, 'isNumeric': false},
          {'name': '课程代码', 'minWidth': 80.0, 'flex': 2, 'isNumeric': false},
          {'name': '课程名称', 'minWidth': 100.0, 'flex': 4, 'isNumeric': false},
          {'name': '课程性质', 'minWidth': 80.0, 'flex': 1, 'isNumeric': false},
          {'name': '课程类别', 'minWidth': 80.0, 'flex': 1, 'isNumeric': false},
          {'name': '补考标记', 'minWidth': 80.0, 'flex': 1, 'isNumeric': false},
          {'name': '考核方式', 'minWidth': 80.0, 'flex': 1, 'isNumeric': false},
          {'name': '学时', 'minWidth': 60.0, 'flex': 1, 'isNumeric': true},
          {'name': '学分', 'minWidth': 60.0, 'flex': 1, 'isNumeric': true},
          {'name': '成绩', 'minWidth': 60.0, 'flex': 1, 'isNumeric': true},
        ];

        // 计算总的最小宽度和权重
        final totalMinWidth = columnConfig.fold<double>(
          0,
          (sum, col) => sum + (col['minWidth'] as double),
        );
        final totalFlex = columnConfig.fold<int>(
          0,
          (sum, col) => sum + (col['flex'] as int),
        );

        // 决定是否需要水平滚动
        final needsHorizontalScroll = availableWidth < totalMinWidth;

        Widget table;
        if (needsHorizontalScroll) {
          // 使用最小宽度
          final columnWidths = columnConfig
              .map((col) => col['minWidth'] as double)
              .toList();
          table = _buildFixedWidthTable(
            columnConfig,
            columnWidths,
            totalMinWidth,
          );
        } else {
          // 按比例分配可用宽度
          final extraWidth = availableWidth - totalMinWidth;
          final columnWidths = columnConfig.map((col) {
            final minWidth = col['minWidth'] as double;
            final flex = col['flex'] as int;
            final extraForThisColumn = extraWidth * (flex / totalFlex);
            return minWidth + extraForThisColumn;
          }).toList();
          table = _buildFixedWidthTable(
            columnConfig,
            columnWidths,
            availableWidth,
          );
        }

        // 总是包装在水平滚动中，以防止溢出
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: table,
          ),
        );
      },
    );
  }

  Widget _buildFixedWidthTable(
    List<Map<String, Object>> columnConfig,
    List<double> columnWidths,
    double tableWidth,
  ) {
    return Container(
      width: tableWidth,
      child: Column(
        children: [
          // 表头
          Container(
            height: 60.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: columnConfig.asMap().entries.map((entry) {
                final index = entry.key;
                final column = entry.value;
                final isCheckbox = index == 0;

                if (isCheckbox) {
                  // 全选checkbox列
                  return Container(
                    width: columnWidths[index],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Checkbox(
                      value: _isAllSelected,
                      onChanged: (_) => _toggleSelectAll(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                } else {
                  return _buildHeaderCell(
                    column['name'] as String,
                    columnWidths[index],
                    isNumeric: column['isNumeric'] as bool,
                  );
                }
              }).toList(),
            ),
          ),
          // 数据行
          ..._filteredGrades!.asMap().entries.map((entry) {
            final index = entry.key;
            final grade = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              height: 80.0,
              decoration: BoxDecoration(
                color: isEven
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(children: _buildDataRow(grade, columnWidths)),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Widget> _buildDataRow(CourseGradeItem grade, List<double> columnWidths) {
    return [
      // Checkbox
      _buildDataCell(
        Checkbox(
          value: _selectedCourseIds.contains(grade.courseId),
          onChanged: (_) => _toggleCourseSelection(grade.courseId),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        columnWidths[0],
      ),
      _buildDataCell(_buildTermCell(grade), columnWidths[1]),
      _buildDataCell(_buildSchoolCell(grade), columnWidths[2]),
      _buildDataCell(
        Text(grade.courseId, style: const TextStyle(fontSize: 14)),
        columnWidths[3],
      ),
      _buildDataCell(_buildCourseNameCell(grade), columnWidths[4]),
      _buildDataCell(
        Text(grade.type, style: const TextStyle(fontSize: 14)),
        columnWidths[5],
      ),
      _buildDataCell(
        Text(grade.category, style: const TextStyle(fontSize: 14)),
        columnWidths[6],
      ),
      _buildDataCell(_buildMakeupStatusCell(grade), columnWidths[7]),
      _buildDataCell(
        Text(grade.examType ?? '-', style: const TextStyle(fontSize: 14)),
        columnWidths[8],
      ),
      _buildDataCell(
        Text(grade.hours.toString()),
        columnWidths[9],
        isNumeric: true,
      ),
      _buildDataCell(
        Text(grade.credit.toString()),
        columnWidths[10],
        isNumeric: true,
      ),
      _buildDataCell(
        Text(
          grade.score.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: grade.score >= 60 ? Colors.green : Colors.red,
          ),
        ),
        columnWidths[11],
        isNumeric: true,
      ),
    ];
  }

  Widget _buildHeaderCell(String text, double width, {bool isNumeric = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: isNumeric ? TextAlign.center : TextAlign.left,
        maxLines: 2,
      ),
    );
  }

  Widget _buildDataCell(Widget child, double width, {bool isNumeric = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: isNumeric ? Alignment.center : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  Widget _buildTermCell(CourseGradeItem grade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          grade.termName,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        if (grade.termNameAlt.isNotEmpty)
          Text(
            grade.termNameAlt,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  Widget _buildSchoolCell(CourseGradeItem grade) {
    if (grade.schoolName == null && grade.schoolNameAlt == null) {
      return const Text('-');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (grade.schoolName != null)
          Text(
            grade.schoolName!,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        if (grade.schoolNameAlt != null && grade.schoolNameAlt!.isNotEmpty)
          Text(
            grade.schoolNameAlt!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  Widget _buildCourseNameCell(CourseGradeItem grade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          grade.courseName,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        if (grade.courseNameAlt != null && grade.courseNameAlt!.isNotEmpty)
          Text(
            grade.courseNameAlt!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  Widget _buildMakeupStatusCell(CourseGradeItem grade) {
    if (grade.makeupStatus == null && grade.makeupStatusAlt == null) {
      return const Text('-');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (grade.makeupStatus != null)
          Text(
            grade.makeupStatus!,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        if (grade.makeupStatusAlt != null && grade.makeupStatusAlt!.isNotEmpty)
          Text(
            grade.makeupStatusAlt!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }
}
