import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/card/card_filter.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/shimmer/shimmer_list_tile.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/pages/add_product/subcategory.dart';

class ChoseClass {
  late String id;
  final String name;

  ChoseClass({this.id = "", this.name = ""});
}

List<ChoseClass> listMainPostType = [
  ChoseClass(id: "0", name: "Заказы"),
  ChoseClass(id: "2", name: "Товары"),
];

List<ChoseClass> combinedList = [
  ...listMainPostType.map((item) => ChoseClass(id: item.id, name: item.name)),
];

@RoutePage(name: 'EditUserProductRoute')
class EditUserProduct extends StatefulWidget {
  final Product products;
  final PostImage? postImage;

  const EditUserProduct({super.key, this.postImage, required this.products});

  @override
  State<EditUserProduct> createState() => _EditUserProductState();
}

class _EditUserProductState extends State<EditUserProduct> {
  final _mediaProcessor = MediaProcessor();
  bool _isSubmittingForm = false;
  bool _isProcessingMedia = false;
  late EnumRequestType requestType;
  final _formKey = GlobalKey<FormState>();
  bool _popped = false;
  late Product product;
  String selectedValue = "";
  String categoryName = "Выберите категорию";
  List<ChoseClass> listMain = listMainPostType;

  late final TextEditingController nameCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController priceCtrl;

  late List<PostImage> _serverImages;

  @override
  void initState() {
    super.initState();
    product = Product.clone(widget.products);
    _serverImages = List<PostImage>.from(widget.products.image_post);

    categoryName = widget.products.categories?.name ?? "Выберите категорию";

    if ((widget.products.categories?.name ?? '').isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveCategoryName(widget.products.category);
      });
    }
    selectedValue = (widget.products.postType?.isNotEmpty ?? false)
        ? widget.products.postType!
        : "2";

    nameCtrl = TextEditingController(text: widget.products.name);
    descCtrl = TextEditingController(text: widget.products.description);
    priceCtrl = TextEditingController(
      text: (widget.products.price == null || widget.products.price == 0)
          ? ''
          : widget.products.price!.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant EditUserProduct oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.products != widget.products) {
      product = Product.clone(widget.products);
      _serverImages = List<PostImage>.from(widget.products.image_post);

      nameCtrl.text = widget.products.name;
      descCtrl.text = widget.products.description;

      priceCtrl.text =
          widget.products.price == null || widget.products.price == 0
              ? ''
              : widget.products.price!.toString();
    }
  }

  Future<void> _handleRefresh() async {
    context.read<ProductBloc>().add(
          GetProductInfo(widget.products.id),
        );
  }

  Future<void> _resolveCategoryName(String? id) async {
    if (id == null || id.isEmpty) return;

    final catBloc = context.read<CategoryBloc>();

    final cached = catBloc.state.categories.where((c) => c.id == id).toList();
    if (cached.isNotEmpty) {
      if (!mounted) return;
      setState(() => categoryName = cached.first.name);
      return;
    }

    catBloc.add(CategoryGetEvent(id));
    try {
      final state = await catBloc.stream
          .firstWhere(
            (s) => !s.isLoading && s.currentCategory?.id == id,
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final name = state.currentCategory?.name;
      if (name != null && name.isNotEmpty) {
        setState(() => categoryName = name);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  List<MediaFile> mediaFiles = [];

  void deleteImagePost(int index) {
    if (_serverImages.length <= 1 && mediaFiles.isEmpty) {
      showMessage(
        context,
        ['Нельзя удалить последнее фото. Сначала добавьте новое'],
        EnumStatusMessage.error,
      );
      return;
    }

    if (index < 0 || index >= _serverImages.length) return;

    final image = _serverImages[index];

    context.read<ProductBloc>().add(
          ProductImageDelete(image.id),
        );

    setState(() {
      _serverImages.removeAt(index);

      if (index < product.image_post.length) {
        product.image_post.removeAt(index);
      }
    });
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var skippedNoPath = 0;
        var addedCount = 0;
        for (var file in result.files) {
          final path = file.path;
          if (path == null || path.isEmpty) {
            skippedNoPath++;
            continue;
          }
          final added = await _processMediaFile(File(path));
          if (added) addedCount++;
        }
        // One summary toast for the whole batch — showing it per file made
        // the message look "stuck" while several files were processing.
        if (addedCount > 0 && mounted) {
          showMessage(
            context,
            [
              addedCount == 1
                  ? 'Файл успешно добавлен'
                  : 'Добавлено $addedCount файлов'
            ],
            EnumStatusMessage.success,
          );
        }
        if (skippedNoPath > 0 && mounted) {
          showMessage(
            context,
            ['Пропущено $skippedNoPath файлов: путь к файлу недоступен'],
            EnumStatusMessage.error,
          );
        }
      }
    } on PlatformException catch (e) {
      if (e.code == 'multiple_request') return;
      if (!mounted) return;
      showMessage(
          context,
          ['Не удалось выбрать медиа. Проверьте разрешения приложения'],
          EnumStatusMessage.error);
    } catch (_) {
      if (!mounted) return;
      showMessage(
          context, ['Не удалось выбрать медиа'], EnumStatusMessage.error);
    }
  }

  /// Processes and adds a single media file. Returns whether it was added,
  /// so callers processing a batch can show one summary toast instead of
  /// one per file.
  Future<bool> _processMediaFile(File file) async {
    final mediaType = _mediaProcessor.determineMediaType(file.path);
    final isVideo = mediaType == MediaType.video;

    setState(() => _isProcessingMedia = true);

    if (isVideo) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _VideoProcessingDialog(),
      );
    }

    try {
      MediaFile? mediaFile;

      if (isVideo) {
        mediaFile = await _mediaProcessor.processVideo(
          file,
          onProgress: (_) {},
          onStatusChanged: (_) {},
        );
      } else {
        mediaFile = await _mediaProcessor.processImage(file);
      }

      if (!mounted) return false;
      if (isVideo) Navigator.of(context).pop();

      if (mediaFile != null) {
        setState(() {
          mediaFiles.add(mediaFile!);
          _isProcessingMedia = false;
        });
        return true;
      }

      setState(() => _isProcessingMedia = false);
      return false;
    } on MediaProcessingException catch (e) {
      if (!mounted) return false;
      if (isVideo) Navigator.of(context).pop();
      showMessage(context, [e.message], EnumStatusMessage.error);
      setState(() => _isProcessingMedia = false);
      return false;
    } catch (_) {
      if (!mounted) return false;
      if (isVideo) Navigator.of(context).pop();
      showMessage(
          context, ['Ошибка при обработке медиа'], EnumStatusMessage.error);
      setState(() => _isProcessingMedia = false);
      return false;
    }
  }

  Future<void> _deleteMediaFile(int index) async {
    final mediaFile = mediaFiles[index];
    if (mediaFile.isVideo) {
      await _mediaProcessor.deleteTemporaryFile(mediaFile.file);
      await _mediaProcessor.deleteTemporaryFile(mediaFile.thumbnail);
    }
    setState(() {
      mediaFiles.removeAt(index);
    });
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    final String appBarTitle = widget.products.name.length > 18
        ? '${widget.products.name.substring(0, 18)}…'
        : widget.products.name;

    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -4,
        passive: true,
      ),
      onRefresh: _handleRefresh,
      title: appBarTitle,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextTranslated(
                  "Редактирование",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                ),
                SizedBox(height: 20.h),
                _ServerImagesRow(
                  images: _serverImages,
                  serverImages: _serverImages,
                  isDarkMode: isDarkMode,
                  onDeleteImage: deleteImagePost,
                  isProcessingMedia: _isProcessingMedia,
                  onPickMedia: _pickMedia,
                ),
                SizedBox(height: 10.h),
                if (mediaFiles.isNotEmpty)
                  const TextTranslated(
                    "Новые медиа",
                    style: AppTextStyle.alertDialogText,
                  ),
                SizedBox(height: 10.h),
                _NewMediaRow(
                  mediaFiles: mediaFiles,
                  onDeleteMedia: _deleteMediaFile,
                ),
                SizedBox(height: 15.h),
                SizedBox(height: 15.h),
                const TextTranslated(
                  "Наименование",
                  style: AppTextStyle.alertDialogText,
                ),
                CustomTextField(
                  controller: nameCtrl,
                  isDesc: true,
                  errorText: '"Наименование"',
                  maxLines: 1,
                  inputFormatters: 40,
                  title: 'Введите название (не более 40 символов)',
                  onChanged: (value) {
                    product.name = value;
                  },
                ),
                SizedBox(height: 20.h),
                _CategorySelector(
                  isDarkMode: isDarkMode,
                  categoryName: categoryName,
                  onCategorySelected: (fullName, categoryId) {
                    setState(() {
                      categoryName = fullName;
                      product.category = categoryId;
                    });
                  },
                ),
                SizedBox(height: 25.h),
                const TextTranslated(
                  "Описание",
                  style: AppTextStyle.alertDialogText,
                ),
                CustomTextField(
                  controller: descCtrl,
                  errorText: '"Описание"',
                  inputFormatters: 800,
                  isDesc: true,
                  textInputType: TextInputType.text,
                  maxLines: 6,
                  title: 'Введите описание товара (не более 800 символов)',
                  onChanged: (value) {
                    product.description = value;
                  },
                ),
                SizedBox(height: 25.h),
                _PriceSection(
                  controller: priceCtrl,
                  onChanged: (value) {
                    product.price = double.tryParse(value) ?? 0;
                  },
                ),
                SizedBox(height: 35.h),
                _PostTypeDropdown(
                  selectedValue: selectedValue,
                  onChanged: (value) {
                    setState(() {
                      selectedValue = value;
                      product.postType = selectedValue;
                    });
                  },
                ),
                SizedBox(height: 30.h),
                _SubmitButton(
                  isSubmittingForm: _isSubmittingForm,
                  oldImages: List<PostImage>.from(_serverImages),
                  onSubmit: _handleSubmit,
                  onNavigateAway: () {
                    if (_popped || !mounted) return;

                    _popped = true;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      context.router.pop(product);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_serverImages.isEmpty && mediaFiles.isEmpty) {
      showMessage(
        context,
        ['Добавьте хотя бы одно фото или видео'],
        EnumStatusMessage.error,
      );
      return;
    }

    setState(() {
      _isSubmittingForm = true;
    });
    product.name = nameCtrl.text.trim();
    product.description = descCtrl.text.trim();

    final pText = priceCtrl.text.trim();
    product.price =
        pText.isEmpty ? null : double.tryParse(pText.replaceAll(',', '.'));

    context.read<ProductBloc>().add(
          ProductCreateEvent(
            mediaFiles: mediaFiles,
            results: product,
            requestType: EnumRequestType.patch,
          ),
        );
  }
}

class _ServerImagesRow extends StatelessWidget {
  final List<PostImage> images;
  final List<PostImage> serverImages;
  final bool isDarkMode;
  final ValueChanged<int> onDeleteImage;
  final bool isProcessingMedia;
  final VoidCallback onPickMedia;

  const _ServerImagesRow({
    required this.images,
    required this.serverImages,
    required this.isDarkMode,
    required this.onDeleteImage,
    required this.isProcessingMedia,
    required this.onPickMedia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < images.length; i++)
            _ServerImageCard(
              image: serverImages[i],
              isDarkMode: isDarkMode,
              onDelete: () => onDeleteImage(i),
            ),
          _AddMediaButton(
            isDisabled: isProcessingMedia,
            onTap: onPickMedia,
          ),
        ],
      ),
    );
  }
}

class _ServerImageCard extends StatelessWidget {
  final PostImage image;
  final bool isDarkMode;
  final VoidCallback onDelete;

  const _ServerImageCard({
    required this.image,
    required this.isDarkMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 120.w,
          height: 120.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: image.image,
              fit: BoxFit.cover,
              memCacheWidth:
                  (120.w * MediaQuery.of(context).devicePixelRatio).round(),
              memCacheHeight:
                  (120.h * MediaQuery.of(context).devicePixelRatio).round(),
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 32),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => _DeleteConfirmationDialog(
                  isDarkMode: isDarkMode,
                  onConfirmDelete: () {
                    onDelete();
                    context.router.maybePop();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onConfirmDelete;

  const _DeleteConfirmationDialog({
    required this.isDarkMode,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xff061324) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => context.router.maybePop(),
                  icon: const Icon(Icons.close),
                  iconSize: 30,
                ),
              ],
            ),
            const TextTranslated(
              'Вы действительно хотите удалить?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.h),
            CustomButton(
              isDelete: false,
              title: 'Удалить',
              onPressed: onConfirmDelete,
              borderRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onTap;

  const _AddMediaButton({
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 120.w,
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[200],
        ),
        child: Icon(
          Icons.add,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _VideoProcessingDialog extends StatelessWidget {
  const _VideoProcessingDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const TextTranslated(
                'Обработка видео',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextTranslated(
                'Пожалуйста, подождите...',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMediaRow extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  final Future<void> Function(int index) onDeleteMedia;

  const _NewMediaRow({
    required this.mediaFiles,
    required this.onDeleteMedia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < mediaFiles.length; i++)
            _NewMediaCard(
              mediaFile: mediaFiles[i],
              onDelete: () => onDeleteMedia(i),
            ),
        ],
      ),
    );
  }
}

class _NewMediaCard extends StatelessWidget {
  final MediaFile mediaFile;
  final VoidCallback onDelete;

  const _NewMediaCard({
    required this.mediaFile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        children: [
          SizedBox(
            width: 120.w,
            height: 120.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildMediaPreview(),
            ),
          ),
          if (mediaFile.isVideo)
            Positioned(
              top: 40,
              left: 40,
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Colors.white.withAlpha(200),
              ),
            ),
          if (mediaFile.isVideo && mediaFile.duration != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: _VideoDurationBadge(
                formattedDuration: mediaFile.formattedDuration,
              ),
            ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (mediaFile.isImage) {
      return Image.file(mediaFile.file, fit: BoxFit.cover);
    }
    if (mediaFile.thumbnail != null) {
      return Image.file(mediaFile.thumbnail!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.video_library, size: 40),
    );
  }
}

class _VideoDurationBadge extends StatelessWidget {
  final String formattedDuration;

  const _VideoDurationBadge({required this.formattedDuration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formattedDuration,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final bool isDarkMode;
  final String categoryName;
  final void Function(String fullName, String categoryId) onCategorySelected;

  const _CategorySelector({
    required this.isDarkMode,
    required this.categoryName,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated(
              "Kатегория",
              style: AppTextStyle.alertDialogText,
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xff192536)
                    : const Color(0xffEAE8EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: state.isLoading
                  ? const ShimmerListTile()
                  : ListTile(
                      title: TextTranslated(categoryName),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        final res =
                            await context.router.push<CategoryPickResult>(
                          SubcategoryPickerRoute(
                            list: state.categories.where((c) {
                              final n = c.name.toLowerCase();
                              return !n.contains("статус") &&
                                  !n.contains("склад");
                            }).toList(),
                            fullNameCategories: "",
                          ),
                        );

                        if (!context.mounted || res == null) return;

                        onCategorySelected(res.fullName, res.category.id);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PriceSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PriceSection({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Цена",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: "15",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            const TextTranslated(
              "сом",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const TextTranslated(
          "Если оставить поле пустым, цена будет договорной\nЦена товара указана в рублях",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _PostTypeDropdown extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _PostTypeDropdown({
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Что вы хотите добавить?",
          style: AppTextStyle.alertDialogText,
        ),
        SizedBox(height: 20.h),
        CardFilter(
          child: DropdownButton<String>(
            underline: const SizedBox(),
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down),
            value: selectedValue,
            items: listMainPostType.map((item) {
              return DropdownMenuItem<String>(
                value: item.id,
                child: TextTranslated(item.name),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmittingForm;
  final VoidCallback onSubmit;
  final VoidCallback onNavigateAway;
  final List<PostImage> oldImages;

  const _SubmitButton({
    required this.isSubmittingForm,
    required this.onSubmit,
    required this.onNavigateAway,
    required this.oldImages,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listenWhen: (previous, current) {
        return isSubmittingForm && previous.isLoading && !current.isLoading;
      },
      listener: (context, state) {
        final ok = state.isSuccessCreate && state.errors.isEmpty;

        if (!ok) {
          showMessage(
            context,
            state.errors.isNotEmpty
                ? state.errors
                : ['Не удалось обновить товар'],
            EnumStatusMessage.error,
          );
          return;
        }

        showMessage(
          context,
          ['Товар успешно обновлён'],
          EnumStatusMessage.success,
        );

        for (final image in oldImages) {
          final url = image.image;
          if (url.isNotEmpty) {
            CachedNetworkImage.evictFromCache(url);
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          onNavigateAway();
        });
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: CustomButton(
            isDelete: true,
            borderRadius: 20,
            isLoading: state.isLoading,
            title: 'Изменить',
            onPressed: state.isLoading ? null : onSubmit,
          ),
        );
      },
    );
  }
}
