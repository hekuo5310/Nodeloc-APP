/// NodeLoc 启用的表情反应（discourse-reactions 插件）
/// 通过穷举 PUT /discourse-reactions/posts/{id}/custom-reactions/{emoji}/toggle.json
/// 探测得出（429=已限额即有效，422=未启用）。
/// 字段：API 端点使用的 id + 用于 UI 展示的 unicode 字符
const List<({String id, String emoji, String label})> kReactions = [
  (id: 'heart', emoji: '❤️', label: '红心'),
  (id: '+1', emoji: '👍', label: '赞同'),
  (id: 'laughing', emoji: '😆', label: '哈哈'),
  (id: 'open_mouth', emoji: '😮', label: '惊讶'),
  (id: 'confetti_ball', emoji: '🎉', label: '庆祝'),
];

/// 根据 reaction id 取展示用 emoji 字符
String reactionEmoji(String? id) {
  if (id == null) return '❤';
  for (final r in kReactions) {
    if (r.id == id) return r.emoji;
  }
  return '❤';
}
