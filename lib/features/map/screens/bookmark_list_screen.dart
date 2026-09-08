import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/spot_detail_screen.dart';
import 'package:flutter_application_1/features/map/models/bookmark_model.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';

class DaftarBookmarkPage extends StatefulWidget {
  final int? userId;

  const DaftarBookmarkPage({super.key, this.userId});

  @override
  State<DaftarBookmarkPage> createState() => _DaftarBookmarkPageState();
}

class _DaftarBookmarkPageState extends State<DaftarBookmarkPage> {
  List<BookmarkModel> _bookmarks = [];
  bool _isLoading = true;
  int _activeUserId = 1;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final uid = widget.userId ?? (await DatabaseHelper.instance.getActiveUserId()) ?? 1;
    final list = await DatabaseHelper.instance.getUserBookmarks(uid);
    if (mounted) {
      setState(() {
        _activeUserId = uid;
        _bookmarks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBookmark(BookmarkModel bookmark) async {
    await DatabaseHelper.instance.removeBookmark(_activeUserId, bookmark.spotId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${bookmark.title} dihapus dari Bookmark'),
        backgroundColor: const Color(0xFFC62828),
        duration: const Duration(seconds: 2),
      ),
    );
    _loadBookmarks();
  }

  void _openSpotDetail(BookmarkModel bookmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InformasiTempatPage(
          spotData: {
            'id': bookmark.spotId,
            'title': bookmark.title,
            'location': bookmark.location,
            'type': bookmark.type,
            'imageUrl': bookmark.imageUrl,
            'rating': bookmark.rating ?? '4.8',
            'elevation': bookmark.elevation ?? '',
            'coordinates': bookmark.coordinates ?? '',
          },
        ),
      ),
    ).then((_) => _loadBookmarks());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themeBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.themeText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Spot Favorit & Bookmark',
          style: TextStyle(
            color: context.themeText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _bookmarks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = _bookmarks[index];
                      return _buildBookmarkCard(item, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 64,
                color: context.themePrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Spot Favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.themeText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jelajahi ekspedisi tebing dan goa, lalu ketuk ikon hati untuk menyimpannya ke daftar bookmark akun Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.themeTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BookmarkModel item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSpotDetail(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.themePrimary.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.landscape_rounded,
                          color: context.themePrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Informasi Spot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.themePrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: context.themePrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 13,
                            color: context.themeTextSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol Delete Bookmark
                IconButton(
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE53935),
                    size: 22,
                  ),
                  tooltip: 'Hapus dari Bookmark',
                  onPressed: () => _deleteBookmark(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
