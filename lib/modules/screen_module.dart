abstract class ScreenModule {
  int get height;
  int get width;
  set drawFlag(bool value);

  void clear();

  void drawLoop();

  void draw();

  bool setPixel(int x, int y);
  bool getPixel(int x, int y);
}
