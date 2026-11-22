// كل العناوين في مكان واحد: الروابط تُبنى هنا، ولا تُكتب باليد أبداً.
abstract final class Routes {
  static const menu = '/menu';
  static const orders = '/orders';
  static const account = '/account';
  static const edit = '/account/edit';

  static String drink(String id) => '/menu/$id';
  static String order(int id) => '/orders/$id';
  static String menuUpTo(int max) =>
      Uri(path: menu, queryParameters: {'max': '$max'}).toString();
  static String signIn({required String from}) =>
      Uri(path: '/signin', queryParameters: {'from': from}).toString();
}
