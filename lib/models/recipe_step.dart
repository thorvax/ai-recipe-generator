/// RECIPE_STEP entity (stored inside the recipe document).
class RecipeStep {
  final int stepNumber;
  final String instruction;

  const RecipeStep({required this.stepNumber, required this.instruction});

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: (map['step_number'] as num?)?.toInt() ?? 0,
      instruction: map['instruction']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'step_number': stepNumber,
        'instruction': instruction,
      };
}
