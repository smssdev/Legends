import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const CarefulMenu()));

class CarefulMenu extends StatelessWidget {
  const CarefulMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('القائمة')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final (name, about, price) in drinks)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          // وقفة واحدة لقارئ الشاشة: الاسم والوصف والسعر تُقرأ معاً.
                          child: MergeSemantics(
                            child: Row(
                              spacing: 12,
                              children: [
                                // الصورة زينة: الاسم يقول ما هي.
                                ExcludeSemantics(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.brown,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_cafe,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: text.titleMedium),
                                      Text(
                                        about,
                                        style: text.bodySmall!.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      // تحت الاسم لا بجانبه: في الأحجام الكبيرة لا يبقى في الصف عرض زائد.
                                      Text(
                                        '$price جنيه',
                                        style: text.labelLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // كل زر أيقونة يقول ما يفعل، ولأي مشروب.
                        IconButton(
                          tooltip: 'احفظ $name',
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border),
                        ),
                        IconButton.filled(
                          tooltip: 'أضف $name',
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: colors.primaryContainer,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            // النص الكبير ينتقل إلى سطر ثانٍ بدل أن يخرج من الشاشة.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text('المجموع: 90 جنيه', style: text.titleLarge),
                FilledButton(
                  onPressed: () {},
                  child: const Text('إتمام الطلب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
