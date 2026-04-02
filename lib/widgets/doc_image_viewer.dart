import 'package:flutter/material.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DocImageViewer extends StatefulWidget {
  final String label;
  final String? path;
  final int expiresIn;

  const DocImageViewer({
    super.key,
    required this.label,
    this.path,
    this.expiresIn = 86400,
  });

  @override
  State<DocImageViewer> createState() => _DocImageViewerState();
}

class _DocImageViewerState extends State<DocImageViewer> {
  String? _signedUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void didUpdateWidget(DocImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    if (widget.path == null || widget.path!.isEmpty) {
      setState(() {
        _signedUrl = null;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final url = await StorageService().getDocumentSignedUrl(widget.path!);
    if (mounted) {
      setState(() {
        _signedUrl = url;
        _loading = false;
      });
    }
  }

  void _showFullImage() {
    if (_signedUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(_signedUrl!),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.background,
          ),
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _signedUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: _showFullImage,
                        child: CachedNetworkImage(
                          imageUrl: _signedUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 32),
                          Text('Upload nahi hua',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}
