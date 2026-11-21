int square(int n) {
  return n * n;
}

// تعبير واحد؟ السهم => يحل محل { return ...; }.
int cube(int n) => n * n * n;

// المعاملات المسماة تُكتب بأسمائها؛ والمطلوب منها لا بد أن يُعطى.
double price({required int cups, double each = 12.5}) => cups * each;

// المعاملات الموضعية الاختيارية بين قوسين مربعين.
String greet(String name, [String greeting = 'مرحباً']) => '$greeting، $name!';

void main() {
  print(square(4));
  print(cube(3));
  print(price(cups: 2));
  print(price(each: 20, cups: 3));
  print(greet('سارة'));
  print(greet('عمر', 'صباح الخير'));
}
