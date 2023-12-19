class Diary {
  int? diaryId; // 自增的，可以不传
  String date, title, content;
  String? tags, category, mood, photos, gmtCreate, gmtModified;
  int? userId;

  Diary({
    this.diaryId,
    required this.date,
    required this.title,
    required this.content,
    this.tags,
    this.category,
    this.mood,
    this.photos,
    this.userId,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "diary_id": diaryId,
      "date": date,
      "title": title,
      "content": content,
      "tags": tags,
      "category": category,
      "mood": mood,
      "photos": photos,
      "user_id": userId,
      "gmt_create": gmtCreate,
      "gmt_modified": gmtModified,
    };
  }

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      diaryId: map['diary_id'] as int?,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: map['tags'] as String?,
      category: map['category'] as String?,
      mood: map['mood'] as String?,
      photos: map['photos'] as String?,
      userId: map['user_id'] as int?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    Diary{
      "diaryId": $diaryId, "date": $date, "title": $title, "content": ${content.length},
      "tags": $tags, "category": $category, "mood": $mood, 
      "photos": $photos,
      "userId": $userId, "gmtCreate": $gmtCreate, "gmtModified": $gmtModified,
    ''';
  }
}
