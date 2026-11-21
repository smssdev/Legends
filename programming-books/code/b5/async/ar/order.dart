void main() {
  print('واحد');
  Future.delayed(Duration(milliseconds: 100), () => print('ثلاثة'));
  print('اثنان');
}
