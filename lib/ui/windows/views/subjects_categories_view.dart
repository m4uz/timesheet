import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/ui/windows/infobar.dart';

class SubjectsCategoriesView extends StatefulWidget {
  const SubjectsCategoriesView({super.key});

  @override
  State<SubjectsCategoriesView> createState() =>
      _SubjectsCategoriesViewState();
}

class _SubjectsCategoriesViewState extends State<SubjectsCategoriesView> {
  final TextEditingController _subjectsSearchController =
      TextEditingController();
  final TextEditingController _categoriesSearchController =
      TextEditingController();

  final Set<Subject> _selectedSubjects = {};
  final Set<Category> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _subjectsSearchController.addListener(() => setState(() {}));
    _categoriesSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subjectsSearchController.dispose();
    _categoriesSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectsCategoriesProvider>(
      builder: (context, provider, _) {
        final successMsg = provider.successMsg;
        final errorMsg = provider.errorMsg;
        if (successMsg != null || errorMsg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (successMsg != null) {
              InfoBarManager.success(successMsg);
              provider.clearSuccessMsg();
            }
            if (errorMsg != null) {
              InfoBarManager.error(errorMsg);
              provider.clearErrorMsg();
            }
          });
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Subjects & Categories'),
            commandBar: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --------------------------------------------------
                // Refresh data
                // --------------------------------------------------
                Tooltip(
                  message: 'Refresh subjects and categories',
                  child: IconButton(
                    icon: const Icon(FluentIcons.refresh),
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.loadSubjectsAndCategories(),
                  ),
                ),
                const SizedBox(width: 8),
                // --------------------------------------------------
                // Save changes
                // --------------------------------------------------
                Tooltip(
                  message: 'Save subjects and categories',
                  child: FilledButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.updateSubjectsAndCategories(),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
          content: provider.isLoading
              ? const Center(child: ProgressRing())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------------
                      // Subjects panel
                      // --------------------------------------------------
                      Expanded(
                        child: _ListPanel<Subject>(
                          title: 'Subjects',
                          searchController: _subjectsSearchController,
                          items: provider.subjects,
                          selectedItems: _selectedSubjects,
                          itemToString: (subject) => subject.uri,
                          isDisabled: provider.isLoading,
                          onItemToggle: (subject) {
                            setState(() {
                              if (_selectedSubjects.contains(subject)) {
                                _selectedSubjects.remove(subject);
                              } else {
                                _selectedSubjects.add(subject);
                              }
                            });
                          },
                          onSelectAll: (filteredItems) {
                            setState(() {
                              final allFilteredSelected = filteredItems
                                  .every((item) =>
                                      _selectedSubjects.contains(item));
                              if (allFilteredSelected) {
                                for (final item in filteredItems) {
                                  _selectedSubjects.remove(item);
                                }
                              } else {
                                _selectedSubjects.addAll(filteredItems);
                              }
                            });
                          },
                          onDeleteSelected: () {
                            setState(() {
                              for (final subject in _selectedSubjects) {
                                provider.deleteSubject(subject);
                              }
                              _selectedSubjects.clear();
                            });
                          },
                          onDeleteItem: (subject) {
                            setState(() {
                              provider.deleteSubject(subject);
                              _selectedSubjects.remove(subject);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      // --------------------------------------------------
                      // Categories panel
                      // --------------------------------------------------
                      Expanded(
                        child: _ListPanel<Category>(
                          title: 'Categories',
                          searchController: _categoriesSearchController,
                          items: provider.categories,
                          selectedItems: _selectedCategories,
                          itemToString: (category) => category.name,
                          isDisabled: provider.isLoading,
                          onItemToggle: (category) {
                            setState(() {
                              if (_selectedCategories.contains(category)) {
                                _selectedCategories.remove(category);
                              } else {
                                _selectedCategories.add(category);
                              }
                            });
                          },
                          onSelectAll: (filteredItems) {
                            setState(() {
                              final allFilteredSelected = filteredItems.every(
                                  (item) =>
                                      _selectedCategories.contains(item));
                              if (allFilteredSelected) {
                                for (final item in filteredItems) {
                                  _selectedCategories.remove(item);
                                }
                              } else {
                                _selectedCategories.addAll(filteredItems);
                              }
                            });
                          },
                          onDeleteSelected: () {
                            setState(() {
                              for (final category in _selectedCategories) {
                                provider.deleteCategory(category);
                              }
                              _selectedCategories.clear();
                            });
                          },
                          onDeleteItem: (category) {
                            setState(() {
                              provider.deleteCategory(category);
                              _selectedCategories.remove(category);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ListPanel<T> extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.searchController,
    required this.items,
    required this.selectedItems,
    required this.itemToString,
    required this.onItemToggle,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onDeleteItem,
    this.isDisabled = false,
  });

  final String title;
  final TextEditingController searchController;
  final List<T> items;
  final Set<T> selectedItems;
  final String Function(T) itemToString;
  final void Function(T) onItemToggle;
  final void Function(List<T>)? onSelectAll;
  final VoidCallback? onDeleteSelected;
  final void Function(T)? onDeleteItem;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final searchText = searchController.text.toLowerCase();
    final filteredItems = searchText.isEmpty
        ? items
        : items
            .where((item) =>
                itemToString(item).toLowerCase().contains(searchText))
            .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE1E1E1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // Panel title + controls
          // --------------------------------------------------
          Text(
            title,
            style: FluentTheme.of(context).typography.title?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildHeader(context, filteredItems),
          const SizedBox(height: 16),
          // --------------------------------------------------
          // Panel rows
          // --------------------------------------------------
          ...filteredItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      itemToString(item),
                      style: FluentTheme.of(context).typography.body,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    checked: isSelected,
                    onChanged: isDisabled
                        ? null
                        : (_) => onItemToggle(item),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Delete ${itemToString(item)}',
                    child: IconButton(
                      icon: const Icon(FluentIcons.delete),
                      onPressed: (isDisabled || onDeleteItem == null)
                          ? null
                          : () => onDeleteItem!(item),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<T> filteredItems) {
    final allSelected = filteredItems.isNotEmpty &&
        filteredItems.every((item) => selectedItems.contains(item));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextBox(
            controller: searchController,
            placeholder: 'Search $title',
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Select all',
          child: Checkbox(
            checked: allSelected,
            onChanged: (isDisabled || onSelectAll == null)
                ? null
                : (_) => onSelectAll!(filteredItems),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Delete selected',
          child: IconButton(
            icon: const Icon(FluentIcons.delete),
            onPressed: isDisabled ? null : onDeleteSelected,
          ),
        ),
      ],
    );
  }
}
