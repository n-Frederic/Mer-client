// lib/models/eisenhower_matrix_model.dart

class EisenhowerMatrixData {
  final List<String> companyImportantTasks;
  final List<String> companyAssignedTasks;
  final List<String> personalImportantTasks;
  final List<String> personalLogs;
  final bool isLoading;

  EisenhowerMatrixData({
    required this.companyImportantTasks,
    required this.companyAssignedTasks,
    required this.personalImportantTasks,
    required this.personalLogs,
    required this.isLoading,
  });

  EisenhowerMatrixData copyWith({
    List<String>? companyImportantTasks,
    List<String>? companyAssignedTasks,
    List<String>? personalImportantTasks,
    List<String>? personalLogs,
    bool? isLoading,
  }) {
    return EisenhowerMatrixData(
      companyImportantTasks: companyImportantTasks ?? this.companyImportantTasks,
      companyAssignedTasks: companyAssignedTasks ?? this.companyAssignedTasks,
      personalImportantTasks: personalImportantTasks ?? this.personalImportantTasks,
      personalLogs: personalLogs ?? this.personalLogs,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  EisenhowerMatrixData.empty()
      : companyImportantTasks = [],
        companyAssignedTasks = [],
        personalImportantTasks = [],
        personalLogs = [],
        isLoading = false;
}