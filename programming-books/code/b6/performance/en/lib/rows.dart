import 'package:material_ui/material_ui.dart';

var rowBuilds = 0;

class DrinkRow extends StatelessWidget {
  const DrinkRow({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    rowBuilds++;
    return ListTile(
      title: Text('Drink $n'),
      trailing: Text('${40 + n % 5 * 5} EGP'),
    );
  }
}
