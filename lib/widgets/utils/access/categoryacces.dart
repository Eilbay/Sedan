import 'package:optombai/data/models/category/category_model.dart';

List<Category> filterCategoriesByAccess({
  required List<Category> categories,
  required bool isPremium,
}) {
  return categories.where((category) {
    final isStatusCategory = category.name.toLowerCase().startsWith('статус');
    if (isStatusCategory && !isPremium) return false;
    return true;
  }).toList();
}

List<Category> filterOutStatusCategories(List<Category> categories,
    {bool isAdmin = false}) {
  return categories
      .where((cat) {
        final isStatus = cat.name.trim().toLowerCase().startsWith("статус") &&
            cat.name.trim().toLowerCase().contains("склад");
        return isAdmin || !isStatus;
      })
      .map((cat) => cat.copyWith(
            children: filterOutStatusCategories(cat.children, isAdmin: isAdmin),
          ))
      .toList();
}
