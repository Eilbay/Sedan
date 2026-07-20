part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {}

class CategoryAllEvent extends CategoryEvent {
  final List<int>? categoryTypes;
  final bool forceRefresh;

  CategoryAllEvent({this.categoryTypes, this.forceRefresh = false});

  @override
  List<Object?> get props => [categoryTypes, forceRefresh];
}

class CategoryGetEvent extends CategoryEvent {
  final String? id;

  CategoryGetEvent(this.id);

  @override
  List<Object?> get props => [id];
}
