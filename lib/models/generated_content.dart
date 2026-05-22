class GeneratedContent {
  final String id;
  final String originalImageUrl;
  final String? editedImageUrl;
  final String prompt;
  final String? editPrompt;
  final DateTime createdAt;
  final String contentType; // 'original', 'edited'
  final Map<String, dynamic> metadata;

  GeneratedContent({
    required this.id,
    required this.originalImageUrl,
    this.editedImageUrl,
    required this.prompt,
    this.editPrompt,
    required this.createdAt,
    required this.contentType,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalImageUrl': originalImageUrl,
      'editedImageUrl': editedImageUrl,
      'prompt': prompt,
      'editPrompt': editPrompt,
      'createdAt': createdAt,
      'contentType': contentType,
      'metadata': metadata,
    };
  }

  factory GeneratedContent.fromMap(Map<String, dynamic> map) {
    return GeneratedContent(
      id: map['id'] ?? '',
      originalImageUrl: map['originalImageUrl'] ?? '',
      editedImageUrl: map['editedImageUrl'],
      prompt: map['prompt'] ?? '',
      editPrompt: map['editPrompt'],
      createdAt: map['createdAt'] ?? DateTime.now(),
      contentType: map['contentType'] ?? 'original',
      metadata: map['metadata'] ?? {},
    );
  }
}
