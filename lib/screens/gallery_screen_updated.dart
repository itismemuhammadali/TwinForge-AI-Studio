import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';

class GalleryScreenUpdated extends StatefulWidget {
  const GalleryScreenUpdated({super.key});

  @override
  State<GalleryScreenUpdated> createState() => _GalleryScreenUpdatedState();
}

class _GalleryScreenUpdatedState extends State<GalleryScreenUpdated> {
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      context.read<ContentProvider>().loadUserContent(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gallery'),
        backgroundColor: const Color(0xFF0E0E0A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0E0E0A),
      body: Consumer2<AuthProvider, ContentProvider>(
        builder: (context, authProvider, contentProvider, _) {
          if (!authProvider.isAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please log in to view your gallery'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }

          if (contentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (contentProvider.contentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 64, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text('No content yet',
                      style: AppFonts.poppins(
                        size: 16,
                        color: AppColors.muted,
                      )),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: contentProvider.contentList.length,
            itemBuilder: (context, index) {
              final content = contentProvider.contentList[index];
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(context, content),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: content['imageUrl'] != null
                            ? Image.network(
                                content['imageUrl'],
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFF2A2A2A),
                                child: Icon(Icons.image_outlined,
                                    color: AppColors.muted),
                              ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          content['title'] ?? 'Untitled',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              context.read<ContentProvider>().deleteContent(
                    authProvider.currentUser!.uid,
                    content['id'],
                  );
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
