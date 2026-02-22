import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/ui/snackbar.dart';

class SubjectsCategoriesView extends StatefulWidget {
  const SubjectsCategoriesView({super.key});

  @override
  State<SubjectsCategoriesView> createState() => _SubjectsCategoriesViewState();
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
    _subjectsSearchController.addListener(() {
      setState(() {});
    });
    _categoriesSearchController.addListener(() {
      setState(() {});
    });
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
        if (provider.successMsg != null) {
          SnackBarManager.success(provider.successMsg!);
          provider.clearSuccessMsg();
        }
        if (provider.errorMsg != null) {
          SnackBarManager.error(provider.errorMsg!);
          provider.clearErrorMsg();
        }

        return MacosScaffold(
          toolBar: ToolBar(
            title: Text(
              'Subjects & Categories',
              style: MacosTheme.of(context).typography.title2,
            ),
            titleWidth: 250.0,
            leading: MacosTooltip(
              message: 'Toggle Sidebar',
              child: MacosIconButton(
                icon: MacosIcon(
                  CupertinoIcons.sidebar_left,
                  color: CupertinoColors.inactiveGray,
                ),
                boxConstraints: const BoxConstraints(
                  minHeight: 20,
                  minWidth: 20,
                  maxWidth: 32,
                  maxHeight: 32,
                ),
                onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
              ),
            ),
            actions: [
              ToolBarIconButton(
                label: 'Refresh',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.refresh_circled),
                tooltipMessage: 'Refresh subjects and categories',
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.loadSubjectsAndCategories();
                      },
              ),
              ToolBarIconButton(
                label: 'Save',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.cloud_upload),
                tooltipMessage: 'Save subjects and categories',
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.updateSubjectsAndCategories();
                      },
              ),
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                if (provider.isLoading) {
                  return Center(child: ProgressCircle());
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListPanel<Subject>(
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
                                        .every(
                                          (item) =>
                                              _selectedSubjects.contains(item),
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
                            Expanded(
                              child: ListPanel<Category>(
                                title: 'Categories',
                                searchController: _categoriesSearchController,
                                items: provider.categories,
                                selectedItems: _selectedCategories,
                                itemToString: (category) => category.name,
                                isDisabled: provider.isLoading,
                                onItemToggle: (category) {
                                  setState(() {
                                    if (_selectedCategories.contains(
                                      category,
                                    )) {
                                      _selectedCategories.remove(category);
                                    } else {
                                      _selectedCategories.add(category);
                                    }
                                  });
                                },
                                onSelectAll: (filteredItems) {
                                  setState(() {
                                    final allFilteredSelected = filteredItems
                                        .every(
                                          (item) => _selectedCategories
                                              .contains(item),
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
                                    for (final category
                                        in _selectedCategories) {
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
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class ListPanel<T> extends StatelessWidget {
  const ListPanel({
    super.key,
    required this.title,
    required this.searchController,
    required this.items,
    required this.selectedItems,
    required this.itemToString,
    required this.onItemToggle,
    this.isDisabled = false,
    this.onSelectAll,
    this.onDeleteSelected,
    this.onDeleteItem,
  });

  final String title;
  final TextEditingController searchController;
  final List<T> items;
  final Set<T> selectedItems;
  final String Function(T) itemToString;
  final Function(T) onItemToggle;
  final bool isDisabled;
  final Function(List<T>)? onSelectAll;
  final VoidCallback? onDeleteSelected;
  final Function(T)? onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final searchText = searchController.text.toLowerCase();
    final filteredItems = searchText.isEmpty
        ? items
        : items
              .where(
                (item) => itemToString(item).toLowerCase().contains(searchText),
              )
              .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MacosTheme.of(context).typography.headline),
              const SizedBox(height: 8),
              _buildHeader(context, filteredItems),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: filteredItems.map((item) {
              final isSelected = selectedItems.contains(item);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: MacosTheme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: _buildItemRow(
                  context: context,
                  item: item,
                  isSelected: isSelected,
                  onItemToggle: onItemToggle,
                  items: items,
                  selectedItems: selectedItems,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<T> filteredItems) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRect(
            child: MacosSearchField(
              controller: searchController,
              placeholder: 'Search $title',
              onChanged: (value) {},
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: MacosCheckbox(
            value:
                filteredItems.isNotEmpty &&
                filteredItems.every((item) => selectedItems.contains(item)),
            onChanged: (isDisabled || onSelectAll == null)
                ? null
                : (value) => onSelectAll!(filteredItems),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: MacosTooltip(
            message: 'Delete selected',
            child: MacosIconButton(
              icon: const MacosIcon(CupertinoIcons.delete),
              onPressed: isDisabled ? null : onDeleteSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required T item,
    required bool isSelected,
    required Function(T) onItemToggle,
    required List<T> items,
    required Set<T> selectedItems,
  }) {
    final itemText = itemToString(item);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SelectableText(
            itemText,
            style: MacosTheme.of(context).typography.body,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: MacosCheckbox(
            value: isSelected,
            onChanged: isDisabled ? null : (value) => onItemToggle(item),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: MacosTooltip(
            message: 'Delete $itemText',
            child: MacosIconButton(
              icon: const MacosIcon(CupertinoIcons.delete),
              onPressed: (isDisabled || onDeleteItem == null)
                  ? null
                  : () => onDeleteItem!(item),
            ),
          ),
        ),
      ],
    );
  }
}
