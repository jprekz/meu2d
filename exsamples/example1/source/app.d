module app;

import meu2d;

class DMan : GameObject {
    Texture texture;
    int angle = 0;
    double x = 0.0, y = 0.0, vx = 0.0, vy = 0.0;

    this() {
        texture = Texture("res/image.png");
    }

    override void update() {
        const distx = Mouse.x - x;
        const disty = Mouse.y - y;
        const pow = (distx^^2 + disty^^2) / 1000000;
        vx += distx * pow / 100;
        vy += disty * pow / 100;
        vx *= 0.98; x += vx;
        vy *= 0.98; y += vy;
        angle += 1;
        if (angle % 10 == 0) meuLogger.log("Hi, I am D言語くん. ", x, " ", y);
    }

    override void draw() {
        import std.conv : to;
        texture.draw(x.to!int - 64, y.to!int - 64, 128, 128, Flip.none, angle);
    }
}

MeuLogger meuLogger;

mixin gameMain!(() {
    init(640, 480, "example");
    meuLogger = new MeuLogger(30, "res/mplus-1p-regular.ttf");
    global.add(meuLogger.getGameObject, int.max);
    global.add(new DMan());
    start();
});
