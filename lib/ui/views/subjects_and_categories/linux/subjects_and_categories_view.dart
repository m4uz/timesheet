import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/platform/linux/toolbar_icon_button.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:yaru/yaru.dart';

class SubjectsAndCategoriesView extends StatefulWidget {
  const SubjectsAndCategoriesView({super.key});

  @override
  State<SubjectsAndCategoriesView> createState() =>
      _SubjectsAndCategoriesViewState();
}

class _SubjectsAndCategoriesViewState extends State<SubjectsAndCategoriesView> {
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
    return Consumer<SubjectsAndCategoriesProvider>(
      builder: (context, provider, _) {
        final successMsg = provider.successMsg;
        final errorMsg = provider.errorMsg;
        if (successMsg != null || errorMsg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (successMsg != null) {
              Snackbar.success(successMsg);
              provider.clearSuccessMsg();
            }
            if (errorMsg != null) {
              Snackbar.error(errorMsg);
              provider.clearErrorMsg();
            }
          });
        }

        return Scaffold(
          appBar: YaruWindowTitleBar(
            border: BorderSide.none,
            title: const Text('Subjects & Categories'),
            actions: [
              ToolbarIconButton(
                message: 'Refresh subjects and categories',
                icon: YaruIcons.refresh,
                onPressed: provider.isLoading
                    ? null
                    : () => provider.loadSubjectsAndCategories(),
              ),
              const SizedBox(width: LinuxLayout.space8),
              ToolbarIconButton(
                message: 'Save subjects and categories',
                icon: YaruIcons.network_transmit,
                onPressed: provider.isLoading
                    ? null
                    : () => provider.updateSubjectsAndCategories(),
              ),
              const SizedBox(width: LinuxLayout.space8),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: YaruCircularProgressIndicator())
              : SingleChildScrollView(
                  padding: LinuxLayout.pagePadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ListPanel<Subject>(
                          title: 'Subjects',
                          searchController: _subjectsSearchController,
                          items: provider.subjects,
                          selectedItems: _selectedSubjects,
                          itemToString: (subject) => subject.name.isNotEmpty
                              ? subject.name
                              : subject.uri,
                          matchesSearch: (subject, query) =>
                              subject.name.toLowerCase().contains(query) ||
                              subject.uri.toLowerCase().contains(query),
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
                              final allFilteredSelected = filteredItems.every(
                                (item) => _selectedSubjects.contains(item),
                              );
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
                      const SizedBox(width: LinuxLayout.space20),
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
                                (item) => _selectedCategories.contains(item),
                              );
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
    this.matchesSearch,
    this.isDisabled = false,
  });

  final String title;
  final TextEditingController searchController;
  final List<T> items;
  final Set<T> selectedItems;
  final String Function(T) itemToString;
  final bool Function(T item, String query)? matchesSearch;
  final void Function(T) onItemToggle;
  final void Function(List<T>)? onSelectAll;
  final VoidCallback? onDeleteSelected;
  final void Function(T)? onDeleteItem;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = LinuxLayout.dividerColor(theme);
    final searchText = searchController.text.toLowerCase();
    final filteredItems = searchText.isEmpty
        ? items
        : items
              .where((item) {
                if (matchesSearch != null) {
                  return matchesSearch!(item, searchText);
                }
                return itemToString(item).toLowerCase().contains(searchText);
              })
              .toList();

    return Container(
      padding: LinuxLayout.panelPadding,
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(LinuxLayout.fieldRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LinuxLayout.panelTitleStyle(theme)),
          const SizedBox(height: LinuxLayout.space8),
          _buildHeader(context, filteredItems),
          const SizedBox(height: LinuxLayout.space16),
          ...filteredItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return Container(
              padding: const EdgeInsets.symmetric(
                vertical: LinuxLayout.space8,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dividerColor,
                    width: LinuxLayout.rowDividerWidth,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      itemToString(item),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: LinuxLayout.space8),
                  Checkbox(
                    value: isSelected,
                    onChanged: isDisabled ? null : (_) => onItemToggle(item),
                  ),
                  const SizedBox(width: LinuxLayout.space8),
                  IconButton(
                    tooltip: 'Delete ${itemToString(item)}',
                    icon: Icon(
                      YaruIcons.trash,
                      size: LinuxLayout.rowIconSize,
                    ),
                    onPressed: (isDisabled || onDeleteItem == null)
                        ? null
                        : () => onDeleteItem!(item),
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
    final allSelected =
        filteredItems.isNotEmpty &&
        filteredItems.every((item) => selectedItems.contains(item));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search $title',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LinuxLayout.space12,
                vertical: LinuxLayout.space8,
              ),
            ),
          ),
        ),
        const SizedBox(width: LinuxLayout.space8),
        Tooltip(
          message: 'Select all',
          child: Checkbox(
            value: allSelected,
            onChanged: (isDisabled || onSelectAll == null)
                ? null
                : (_) => onSelectAll!(filteredItems),
          ),
        ),
        const SizedBox(width: LinuxLayout.space8),
        IconButton(
          tooltip: 'Delete selected',
          icon: Icon(
            YaruIcons.trash,
            size: LinuxLayout.rowIconSize,
          ),
          onPressed: isDisabled ? null : onDeleteSelected,
        ),
      ],
    );
  }
}
