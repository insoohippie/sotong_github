import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

enum CategoryEditRowType {
  planHeader,
  planItem,
  planAddButton,
  refHeader,
  refItem,
  refAddButton,
}

class CategoryEditRow {
  const CategoryEditRow.planHeader()
      : type = CategoryEditRowType.planHeader,
        planItem = null,
        refItem = null;

  const CategoryEditRow.planItem(this.planItem)
      : type = CategoryEditRowType.planItem,
        refItem = null;

  const CategoryEditRow.planAddButton()
      : type = CategoryEditRowType.planAddButton,
        planItem = null,
        refItem = null;

  const CategoryEditRow.refHeader()
      : type = CategoryEditRowType.refHeader,
        planItem = null,
        refItem = null;

  const CategoryEditRow.refItem(this.refItem)
      : type = CategoryEditRowType.refItem,
        planItem = null;

  const CategoryEditRow.refAddButton()
      : type = CategoryEditRowType.refAddButton,
        planItem = null,
        refItem = null;

  final CategoryEditRowType type;
  final CategoryEditItem? planItem;
  final RefCategoryItem? refItem;

  bool get isFixed {
    return type == CategoryEditRowType.planHeader ||
        type == CategoryEditRowType.planAddButton ||
        type == CategoryEditRowType.refHeader ||
        type == CategoryEditRowType.refAddButton;
  }

  String get key {
    switch (type) {
      case CategoryEditRowType.planHeader:
        return 'header-plan';

      case CategoryEditRowType.planItem:
        return 'plan-${planItem!.categoryKey}';

      case CategoryEditRowType.planAddButton:
        return 'button-plan-add';

      case CategoryEditRowType.refHeader:
        return 'header-ref';

      case CategoryEditRowType.refItem:
        return 'ref-${refItem!.categoryKey}';

      case CategoryEditRowType.refAddButton:
        return 'button-ref-add';
    }
  }
}