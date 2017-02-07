abstract class ScreenModule {
  int get height;

  int get width;

  void clear();

  void draw();

  bool setPixel(int x, int y);
  bool getPixel(int x, int y);
}
