enum FeelingReactionType { same, sendingStrength, beenThere }

class FeelingReactionDef {
  const FeelingReactionDef({
    required this.type,
    required this.emoji,
    required this.label,
  });

  final FeelingReactionType type;
  final String emoji;
  final String label;
}

const feelingReactions = [
  FeelingReactionDef(type: FeelingReactionType.same, emoji: '🫂', label: 'Same'),
  FeelingReactionDef(type: FeelingReactionType.sendingStrength, emoji: '💪', label: 'Strength'),
  FeelingReactionDef(type: FeelingReactionType.beenThere, emoji: '🙏', label: 'Been there'),
];

FeelingReactionDef reactionDef(FeelingReactionType type) =>
    feelingReactions.firstWhere((r) => r.type == type);
