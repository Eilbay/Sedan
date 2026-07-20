import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/language_bloc/extensions/translation_context_extension.dart';
import 'package:optombai/bloc/upload_cubit/upload_cubit.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/pages/add_product/subcategory.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:optombai/services/media/video_thumbnail_generator.dart';
import 'package:optombai/services/media/video_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/widgets/bottom_nav.dart';

export 'product_type_config.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/pages/add_product/product_type_config.dart';

@RoutePage()
class AddProductScreen extends StatefulWidget {
  final Product? products;
  final PostImage? postImage;

  const AddProductScreen({super.key, this.products, this.postImage});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  late Product product;
  late EnumRequestType requestType;
  late TabController _tabController;
  final _mediaProcessor = MediaProcessor();
  bool _isProcessingMedia = false;
  int _mediaTabIndex = 0;
  File? _rawVideoFile;
  String? _videoProcessingError;
  String _videoProcessingStatus = '';

  String name = "Выбрать категорию";
  List<ChoseClass> listMain = listMainPostType2;
  List<ChoseClass> listProv = listProviderAndManufacturer;
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    product = widget.products ?? Product();
    product.postType = "2";
    requestType = EnumRequestType.post;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  List<MediaFile> photoFiles = [];
  MediaFile? videoFile;

  void addProduct() {
    Product newProduct = product;
    var user = context.read<UserBloc>().state.user;
    newProduct.owner = user;

    final allMediaFiles = [...photoFiles];

    // Pass the video as a RAW file so the upload pipeline runs
    // MediaProcessor.processVideo (validation + thumbnail). The original is
    // uploaded as-is; compression is handled server-side.
    context.read<UploadCubit>().startUpload(
          product: newProduct,
          mediaFiles: allMediaFiles,
          requestType: EnumRequestType.post,
          rawVideoFile: videoFile?.file,
        );

    _resetForm();
    BottomNav.of(context)?.setTab(0);
  }

  void _resetForm() {
    setState(() {
      product = Product();
      photoFiles = [];
      videoFile = null;
      _rawVideoFile = null;
      _videoProcessingError = null;
      _videoProcessingStatus = '';
      name = "Выбрать категорию";
      selectedValue = "2";
      product.postType = "2";
      _mediaTabIndex = 0;
      _tabController.index = 0;
    });
    nameController.clear();
    descController.clear();
    priceController.clear();
    _formKey.currentState?.reset();
  }

  static const int _maxPhotos = 10;

  Future<void> _pickPhotos() async {
    if (photoFiles.length >= _maxPhotos) {
      showMessage(
          context, ['Максимум $_maxPhotos фото'], EnumStatusMessage.error);
      return;
    }

    try {
      final picker = ImagePicker();
      debugPrint('[AddProduct] Opening photo gallery...');
      final images = await picker.pickMultiImage();
      debugPrint('[AddProduct] Picked ${images.length} photos');

      if (images.isNotEmpty) {
        final remaining = _maxPhotos - photoFiles.length;
        final filesToProcess = images.take(remaining);
        var addedCount = 0;
        for (var image in filesToProcess) {
          final added = await _processPhotoFile(File(image.path));
          if (added) addedCount++;
        }
        // One summary toast for the whole batch — showing it per file made
        // the message look "stuck" while several photos were processing.
        if (addedCount > 0 && mounted) {
          showMessage(
            context,
            [
              addedCount == 1
                  ? 'Фото успешно добавлено'
                  : 'Добавлено $addedCount фото'
            ],
            EnumStatusMessage.success,
          );
        }
        if (images.length > remaining && mounted) {
          showMessage(
            context,
            [
              'Добавлено $remaining из ${images.length} фото (макс. $_maxPhotos)'
            ],
            EnumStatusMessage.error,
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('[AddProduct] PlatformException: ${e.code} ${e.message}');
      if (e.code == 'multiple_request') return;
      if (!mounted) return;
      showMessage(
          context,
          ['Не удалось выбрать фото. Проверьте разрешения приложения'],
          EnumStatusMessage.error);
    } catch (e) {
      debugPrint('[AddProduct] Photo pick error: $e');
      if (!mounted) return;
      showMessage(
          context, ['Не удалось выбрать фото'], EnumStatusMessage.error);
    }
  }

  /// Processes and adds a single photo. Returns whether it was added, so
  /// callers processing a batch can show one summary toast instead of one
  /// per file.
  Future<bool> _processPhotoFile(File file) async {
    try {
      setState(() => _isProcessingMedia = true);

      final mediaFile = await _mediaProcessor.processImage(file);

      if (!mounted) return false;

      if (mediaFile != null) {
        setState(() {
          photoFiles.add(mediaFile);
          _isProcessingMedia = false;
        });
        return true;
      }

      setState(() => _isProcessingMedia = false);
      showMessage(
        context,
        ['Не удалось обработать фото'],
        EnumStatusMessage.error,
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      showMessage(context, [e.toString()], EnumStatusMessage.error);
      setState(() => _isProcessingMedia = false);
      return false;
    }
  }

  Future<void> _deletePhoto(int index) async {
    setState(() => photoFiles.removeAt(index));
    showMessage(context, ['Фото удалено'], EnumStatusMessage.success);
  }

  Future<void> _pickVideo() async {
    debugPrint(
        '[AddProduct] _pickVideo() called, _mediaTabIndex=$_mediaTabIndex');
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);

      debugPrint(
          '[AddProduct] ImagePicker result: ${video != null ? video.path : 'null'}');

      if (video != null) {
        await _processVideoFile(File(video.path));
      } else {
        debugPrint('[AddProduct] ImagePicker cancelled');
      }
    } on PlatformException catch (e) {
      debugPrint('[AddProduct] PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'multiple_request') return;
      if (!mounted) return;
      showMessage(
          context,
          ['Не удалось выбрать видео. Проверьте разрешения приложения'],
          EnumStatusMessage.error);
    } catch (e) {
      debugPrint('[AddProduct] _pickVideo error: $e');
      if (!mounted) return;
      showMessage(
          context, ['Не удалось выбрать видео'], EnumStatusMessage.error);
    }
  }

  static const int _maxVideoSize = 1024 * 1024 * 1024; // 1 GB
  final _thumbnailGenerator = VideoThumbnailGenerator();

  Future<void> _processVideoFile(File file) async {
    debugPrint('[AddProduct] _processVideoFile() START: ${file.path}');

    setState(() {
      _isProcessingMedia = true;
      _rawVideoFile = file;
      _videoProcessingError = null;
      _videoProcessingStatus = 'Проверка видео...';
      videoFile = null;
    });

    try {
      // 1. Check format.
      if (!VideoValidator.isVideoFile(file.path)) {
        throw MediaProcessingException(
          'Неподдерживаемый формат видео. Используйте: '
          '${VideoValidator.supportedFormats.join(", ")}',
        );
      }

      // 2. Check size (< 1 GB).
      final fileSize = await file.length();
      debugPrint(
          '[AddProduct] video size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');

      if (fileSize > _maxVideoSize) {
        final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(0);
        throw MediaProcessingException(
          'Видео слишком большое ($sizeMb MB). Максимум: 1 GB',
        );
      }

      if (!mounted) return;
      setState(() => _videoProcessingStatus = 'Генерация превью...');

      // 3. Generate thumbnail.
      final thumbnail = await _thumbnailGenerator.generate(file);
      debugPrint('[AddProduct] thumbnail: ${thumbnail?.path}');

      if (!mounted) return;

      setState(() {
        videoFile = MediaFile(
          file: file,
          type: MediaType.video,
          thumbnail: thumbnail,
          size: fileSize,
        );
        _isProcessingMedia = false;
        _rawVideoFile = null;
        _videoProcessingStatus = '';
      });

      debugPrint('[AddProduct] Video ready, size=${videoFile!.formattedSize}');
      showMessage(context, ['Видео добавлено'], EnumStatusMessage.success);
    } on MediaProcessingException catch (e) {
      debugPrint('[AddProduct] MediaProcessingException: ${e.message}');
      if (!mounted) return;
      setState(() {
        _isProcessingMedia = false;
        _videoProcessingError = e.message;
        _videoProcessingStatus = '';
      });
    } catch (e) {
      debugPrint('[AddProduct] Unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _isProcessingMedia = false;
        _videoProcessingError = 'Ошибка при обработке видео';
        _videoProcessingStatus = '';
      });
    }
  }

  Future<void> _deleteVideo() async {
    if (videoFile != null) {
      await _mediaProcessor.deleteTemporaryFile(videoFile!.file);
      await _mediaProcessor.deleteTemporaryFile(videoFile!.thumbnail);
    }
    if (!mounted) return;
    setState(() {
      videoFile = null;
      _rawVideoFile = null;
      _videoProcessingError = null;
      _videoProcessingStatus = '';
    });
    showMessage(context, ['Видео удалено'], EnumStatusMessage.success);
  }

  String selectedValue = "2";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: BazarlarAppScaffold(
          products: widget.products != null,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScreenTitle(),
                    SizedBox(height: 16.h),
                    _PostTypeSelector(
                      selectedValue: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value.toString();
                          product.postType = selectedValue;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    _MediaSection(
                      tabController: _tabController,
                      mediaTabIndex: _mediaTabIndex,
                      onTabChanged: (index) {
                        setState(() => _mediaTabIndex = index);
                      },
                      photoFiles: photoFiles,
                      videoFile: videoFile,
                      isProcessingMedia: _isProcessingMedia,
                      rawVideoFile: _rawVideoFile,
                      videoProcessingError: _videoProcessingError,
                      videoProcessingStatus: _videoProcessingStatus,
                      onPickPhotos: _pickPhotos,
                      onDeletePhoto: _deletePhoto,
                      onPickVideo: _pickVideo,
                      onDeleteVideo: _deleteVideo,
                      onRetryVideo: _rawVideoFile != null
                          ? () => _processVideoFile(_rawVideoFile!)
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    const TextTranslated(
                      "Наименование товара",
                      style: AppTextStyle.alertDialogText,
                    ),
                    CustomTextField(
                      isDesc: true,
                      errorText: '"Наименование"',
                      minLines: 1,
                      maxLines: null,
                      inputFormatters: 40,
                      title: 'Введите название (не более 40 символов)',
                      onChanged: (value) {
                        product.name = value;
                      },
                    ),
                    SizedBox(height: 16.h),
                    _CategorySelector(
                      categoryName: name,
                      onCategorySelected: (fullName, catId) {
                        setState(() {
                          name = fullName;
                          product.category = catId;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    CustomTextField(
                      errorText: '"Описание"',
                      inputFormatters: 800,
                      isDesc: true,
                      textInputType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 6,
                      maxLines: null,
                      title: 'Введите описание товара (не более 800 символов)',
                      onChanged: (value) {
                        product.description = value;
                      },
                    ),
                    SizedBox(height: 16.h),
                    _PriceSection(
                      currency: product.currency,
                      onPriceChanged: (value) {
                        final v = value.replaceAll(',', '.');
                        product.price = double.tryParse(v) ?? 0;
                      },
                      onCurrencyChanged: (c) =>
                          setState(() => product.currency = c),
                    ),
                    SizedBox(height: 24.h),
                    _SubmitButton(
                      isProcessingMedia: _isProcessingMedia,
                      formKey: _formKey,
                      photoFiles: photoFiles,
                      videoFile: videoFile,
                      product: product,
                      onSubmit: addProduct,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted widgets
// ---------------------------------------------------------------------------

class _ScreenTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: context.translateText("Добавление новой карточки"),
      builder: (context, snapshot) {
        return TextTranslated(
          snapshot.data ?? "Добавление новой карточки",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        );
      },
    );
  }
}

class _MediaSection extends StatelessWidget {
  final TabController tabController;
  final int mediaTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<MediaFile> photoFiles;
  final MediaFile? videoFile;
  final bool isProcessingMedia;
  final File? rawVideoFile;
  final String? videoProcessingError;
  final String videoProcessingStatus;
  final VoidCallback onPickPhotos;
  final Future<void> Function(int) onDeletePhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onDeleteVideo;
  final VoidCallback? onRetryVideo;

  const _MediaSection({
    required this.tabController,
    required this.mediaTabIndex,
    required this.onTabChanged,
    required this.photoFiles,
    required this.videoFile,
    required this.isProcessingMedia,
    required this.rawVideoFile,
    required this.videoProcessingError,
    required this.videoProcessingStatus,
    required this.onPickPhotos,
    required this.onDeletePhoto,
    required this.onPickVideo,
    required this.onDeleteVideo,
    required this.onRetryVideo,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _MediaTabBar(
            tabController: tabController,
            onTabChanged: onTabChanged,
          ),
          SizedBox(height: 16.h),
          if (mediaTabIndex == 0)
            _PhotosTab(
              photoFiles: photoFiles,
              isProcessingMedia: isProcessingMedia,
              onPickPhotos: onPickPhotos,
              onDeletePhoto: onDeletePhoto,
            ),
          if (mediaTabIndex == 1)
            _VideoTab(
              videoFile: videoFile,
              isProcessingMedia: isProcessingMedia,
              rawVideoFile: rawVideoFile,
              videoProcessingError: videoProcessingError,
              videoProcessingStatus: videoProcessingStatus,
              onPickVideo: onPickVideo,
              onDeleteVideo: onDeleteVideo,
              onRetryVideo: onRetryVideo,
            ),
        ],
      ),
    );
  }
}

class _MediaTabBar extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<int> onTabChanged;

  const _MediaTabBar({
    required this.tabController,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: tabController,
        onTap: onTabChanged,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 18),
                SizedBox(width: 8),
                TextTranslated('Фото'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 18),
                SizedBox(width: 8),
                TextTranslated('Видео'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final List<MediaFile> photoFiles;
  final bool isProcessingMedia;
  final VoidCallback onPickPhotos;
  final Future<void> Function(int) onDeletePhoto;

  const _PhotosTab({
    required this.photoFiles,
    required this.isProcessingMedia,
    required this.onPickPhotos,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (photoFiles.isEmpty)
            GestureDetector(
              onTap: isProcessingMedia ? null : onPickPhotos,
              child: _EmptyPhotoPlaceholder(),
            ),
          for (int i = 0; i < photoFiles.length; i++)
            _PhotoPreviewItem(
              file: photoFiles[i].file,
              onDelete: () => onDeletePhoto(i),
            ),
          _AddPhotoButton(
            isDisabled: isProcessingMedia,
            onTap: onPickPhotos,
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      height: 150.h,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 32),
    );
  }
}

class _PhotoPreviewItem extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _PhotoPreviewItem({
    required this.file,
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
              child: Image.file(
                file,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _DeleteButton(onPressed: onDelete),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onTap;

  const _AddPhotoButton({
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFEDEDED),
          ),
          child: Icon(
            Icons.add,
            color: isDisabled ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _VideoTab extends StatelessWidget {
  final MediaFile? videoFile;
  final bool isProcessingMedia;
  final File? rawVideoFile;
  final String? videoProcessingError;
  final String videoProcessingStatus;
  final VoidCallback onPickVideo;
  final VoidCallback onDeleteVideo;
  final VoidCallback? onRetryVideo;

  const _VideoTab({
    required this.videoFile,
    required this.isProcessingMedia,
    required this.rawVideoFile,
    required this.videoProcessingError,
    required this.videoProcessingStatus,
    required this.onPickVideo,
    required this.onDeleteVideo,
    required this.onRetryVideo,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[_VideoTab] build: isProcessingMedia=$isProcessingMedia, rawVideoFile=${rawVideoFile?.path}, videoProcessingError=$videoProcessingError, videoFile=${videoFile != null}, status=$videoProcessingStatus');

    final String branch;
    if (isProcessingMedia && rawVideoFile != null) {
      branch = 'PROCESSING_INLINE';
    } else if (videoProcessingError != null) {
      branch = 'ERROR_INLINE';
    } else if (videoFile != null) {
      branch = 'VIDEO_PREVIEW';
    } else {
      branch = 'PLACEHOLDER';
    }
    debugPrint('[_VideoTab] rendering branch: $branch');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isProcessingMedia && rawVideoFile != null)
          _VideoProcessingInline(
            fileName: rawVideoFile!.path.split('/').last,
            statusText: videoProcessingStatus,
          )
        else if (videoProcessingError != null)
          _VideoErrorInline(
            error: videoProcessingError!,
            onRetry: onRetryVideo,
            onDelete: onDeleteVideo,
          )
        else if (videoFile != null)
          _VideoPreview(
            videoFile: videoFile!,
            onDelete: onDeleteVideo,
          )
        else
          _VideoPlaceholder(
            isDisabled: isProcessingMedia,
            onTap: onPickVideo,
          ),
        SizedBox(height: 12.h),
        if (videoFile != null)
          Center(
            child: ElevatedButton.icon(
              onPressed: isProcessingMedia ? null : onPickVideo,
              icon: const Icon(Icons.refresh),
              label: const TextTranslated('Заменить видео'),
            ),
          ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onTap;

  const _VideoPlaceholder({
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        child: Container(
          width: 150.w,
          height: 150.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFEDEDED),
          ),
          child: Icon(
            Icons.videocam_outlined,
            size: 50,
            color: isDisabled ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _VideoProcessingInline extends StatelessWidget {
  final String fileName;
  final String statusText;

  const _VideoProcessingInline({
    required this.fileName,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 180.w,
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFEDEDED),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextTranslated(
                statusText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoErrorInline extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  const _VideoErrorInline({
    required this.error,
    required this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220.w,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.red.withValues(alpha: 0.05),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const TextTranslated('Повторить'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (onRetry != null) const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  label: const TextTranslated(
                    'Убрать',
                    style: TextStyle(color: Colors.grey),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final MediaFile videoFile;
  final VoidCallback onDelete;

  const _VideoPreview({
    required this.videoFile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          SizedBox(
            width: 180.w,
            height: 180.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: videoFile.thumbnail != null
                  ? Image.file(
                      videoFile.thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.video_library, size: 50),
                    ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextTranslated(
                videoFile.formattedSize,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _DeleteButton(onPressed: onDelete),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String categoryName;
  final void Function(String fullName, String? catId) onCategorySelected;

  const _CategorySelector({
    required this.categoryName,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return BlocBuilder<CategoryBloc, CategoryState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated(
              "Категории и подкатегории товара",
              style: AppTextStyle.alertDialogText,
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: stateSwitch
                    ? const Color(0xff192536)
                    : const Color(0xffEAE8EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
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
  final String currency;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onCurrencyChanged;

  const _PriceSection({
    required this.currency,
    required this.onPriceChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TextTranslated(
              "Цена",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _CurrencyToggle(
              selected: currency,
              onChanged: onCurrencyChanged,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: "0",
            suffixText: currency,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: onPriceChanged,
        ),
        const SizedBox(height: 6),
        const TextTranslated(
          "Если оставить поле пустым, цена будет договорной",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['KGS', 'USD'].map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF34C759).withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF34C759) : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF34C759) : Colors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PostTypeSelector extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<Object?> onChanged;

  const _PostTypeSelector({
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Row(
      children: listMainPostType2.map((item) {
        final isSelected = selectedValue == item.id.toString();
        final borderColor = isSelected
            ? Theme.of(context).colorScheme.primary
            : (isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB));
        final bgColor = isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : (isDark ? const Color(0xff192536) : Colors.white);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == listMainPostType2.first ? 4 : 0,
              left: item == listMainPostType2.last ? 4 : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(item.id.toString()),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: borderColor, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.id == 2 ? Icons.storefront : Icons.search,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextTranslated(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isProcessingMedia;
  final GlobalKey<FormState> formKey;
  final List<MediaFile> photoFiles;
  final MediaFile? videoFile;
  final Product product;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.isProcessingMedia,
    required this.formKey,
    required this.photoFiles,
    required this.videoFile,
    required this.product,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUploading = context.select((UploadCubit c) {
      final s = c.state;
      return s is UploadProcessing ||
          s is UploadCreating ||
          s is UploadUploading;
    });

    return CustomButton(
      borderRadius: 20,
      isLoading: isUploading || isProcessingMedia,
      title: "Добавить",
      onPressed: isProcessingMedia || isUploading
          ? null
          : () {
              if (!formKey.currentState!.validate()) return;
              if (photoFiles.isEmpty && videoFile == null) {
                showMessage(context, ["Добавьте фото или видео"],
                    EnumStatusMessage.error);
                return;
              }
              if (product.category == null || product.category!.isEmpty) {
                showMessage(
                    context, ["Выберите категорию"], EnumStatusMessage.error);
                return;
              }
              if (product.postType == null || product.postType!.isEmpty) {
                showMessage(context, ["Выберите тип продукта"],
                    EnumStatusMessage.error);
                return;
              }

              onSubmit();
            },
    );
  }
}
