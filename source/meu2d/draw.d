module meu2d.draw;

import std.algorithm;
import std.array : array;
import std.typecons;
import std.conv : to;
import std.file : read;

import derelict.sdl2.sdl;
import gfm.image;

import meu2d.error;
import meu2d.core;


/// RGBA各8ビット(ubyte)によって色を表す構造体です。
struct Color {
    /// 赤チャネル
    ubyte r;
    /// 緑チャネル
    ubyte g;
    /// 青チャネル
    ubyte b;
    /// αチャネル(初期化時は省略可)
    ubyte a = 255;
}

/// 基本図形を描画する際の色を指定します。
void setDrawColor(Color c) {
    SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a).enforceSDL;
}

/// 画面上の座標(x1, y1)から(x2, y2)まで太さ1pxの直線を描画します。
void drawLine(int x1, int y1, int x2, int y2) {
    SDL_RenderDrawLine(renderer, x1, y1, x2, y2).enforceSDL;
}

///画面上の座標(x, y)に1pxの点を描画します。
void drawPoint(int x, int y) {
    SDL_RenderDrawPoint(renderer, x, y).enforceSDL;
}

/// 画面上の座標(x, y)を長方形の左上，wを幅, hを高さとして長方形を描画します。
void drawRect(int x, int y, int w, int h) {
    auto rect = SDL_Rect(x, y, w, h);
    SDL_RenderDrawRect(renderer, &rect).enforceSDL;
}

/// 画面上の座標(x, y)を長方形の左上，wを幅, hを高さとして塗りつぶした長方形を描画します。
void fillRect(int x, int y, int w, int h) {
    auto rect = SDL_Rect(x, y, w, h);
    SDL_RenderFillRect(renderer, &rect).enforceSDL;
}

/// 任意の画像データを表す構造体です。画像は画面上に描画することができます。一度初期化した画像データを後から編集することはできません。
struct Texture {
    
    /// 画像の幅を返します。
    int width() {
        return _width;
    }

    /// 画像の高さを返します。
    int height() {
        return _height;
    }

    private SDLTexture texture;
    private int _x, _y, _width, _height;

    /// pathで指定した画像ファイルを読み込みます。
    this(string path) {
        auto image = loadImage(read(path));
        _x = _y = 0;
        _width = image.w; _height = image.h;
        auto surface = SDL_CreateRGBSurfaceFrom(
            cast(void*)image.pixels, _width, _height,
            32, _width * 4,
            0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000
        );
        texture = new SDLTexture(
            SDL_CreateTextureFromSurface(renderer, surface)
        );
        SDL_FreeSurface(surface);
    }

    // テクスチャの破棄をGCに任せる maybe works
    private class SDLTexture {
        SDL_Texture* texture;
        this(SDL_Texture* t) { texture = t; }
        ~this() {
            SDL_DestroyTexture(texture);
        }
        alias texture this;
    }

    /// pixelsに格納されたビットマップデータを幅w，高さhとして読み込みます。
    this(ubyte[] pixels, int w, int h) {
        _width = w;
        _height = h;
        auto surface = SDL_CreateRGBSurfaceFrom(
            cast(void*)pixels, _width, _height,
            32, _width * 4,
            0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000
        );
        texture = new SDLTexture(
            SDL_CreateTextureFromSurface(renderer, surface)
        );
        SDL_FreeSurface(surface);
    }

    /// 画像を座標(x, y)を左上として幅w, 高さhの範囲で切り取り，新しいTexture構造体として返します。
    Texture trim(int x, int y, int w, int h) {
        Texture r = this;
        r._width = w; r._height = h; r._x += x; r._y += y;
        return r;
    }

    /// 画像を画面上の座標(x, y)に描画します。
    void draw(int x, int y) {
        auto src = SDL_Rect(_x, _y, _width, _height);
        auto dst = SDL_Rect(x, y, _width, _height);
        SDL_RenderCopy(renderer, texture, &src, &dst).enforceSDL;
    }

    /// 画像を幅w，高さhにリサイズし，画面上の座標(x, y)に描画します。
    void draw(int x, int y, int w, int h) {
        auto src = SDL_Rect(_x, _y, _width, _height);
        auto dst = SDL_Rect(x, y, w, h);
        SDL_RenderCopy(renderer, texture, &src, &dst).enforceSDL;
    }

    /// 画像を幅w，高さhにリサイズし，角度angle(度数法)で回転し，fで指定した向きに反転した後，画面上の座標(x, y)に描画します。
    void draw(int x, int y, int w, int h, Flip f, double angle = 0.0) {
        auto src = SDL_Rect(_x, _y, _width, _height);
        auto dst = SDL_Rect(x, y, w, h);
        SDL_RenderCopyEx(renderer, texture, &src, &dst, angle, null, f).enforceSDL;
    }

    /// 画像を幅w，高さhにリサイズし，角度angle(度数法)で回転し，fで指定した向きに反転した後，画面上の座標(x, y)に描画します。画像を回転する際の中心を(center_x, center_y)とします。
    void draw(int x, int y, int w, int h, Flip f, double angle, int center_x, int center_y) {
        auto src = SDL_Rect(_x, _y, _width, _height);
        auto dst = SDL_Rect(x, y, w, h);
        auto center = SDL_Point(center_x, center_y);
        SDL_RenderCopyEx(renderer, texture, &src, &dst, angle, &center, f).enforceSDL;
    }
}

/// 画像の上下左右反転を表す列挙体です。
enum Flip : SDL_RendererFlip {
    none = SDL_FLIP_NONE,
    horizontal = SDL_FLIP_HORIZONTAL,
    vertical = SDL_FLIP_VERTICAL,
    each = SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL
}

Texture renderText(dstring text, int ptSize, string fontName, Color color = Color(255, 255, 255)) {
    auto fontData = loadFont(fontName);
    auto charData = text.map!(dc => fontData.loadChar(ptSize, dc)).array;
    immutable double scale = stbtt_ScaleForPixelHeight(&fontData.info, ptSize);

    immutable int width = charData.map!(cd => (cd.advance*scale).to!int).sum,
                  height = ptSize;

    ubyte[] pixels = new ubyte[width * height * 4]; //RGBA
    foreach (i; 0 .. height) foreach (j; 0 .. width) {
        size_t p = (j + i * width) * 4;
        pixels[p] = color.r; pixels[p + 1] = color.g; pixels[p + 2] = color.b;
    }
    immutable double alpha = color.a / 255.0;

    immutable int baseline = (fontData.ascent * scale).to!int;
    int xpos = -charData[0].xoff;
    foreach (ci, cd; charData) {
        foreach (i; 0 .. cd.h) foreach (j; 0 .. cd.w) {
            immutable size_t gp = (xpos + cd.xoff + j + (baseline + cd.yoff + i) * width) * 4 + 3;
            immutable ubyte src = cd.bitmap[j + i * cd.w],
                            dst = pixels[gp];
            pixels[gp] = min((src + dst * (1.0 - src / 255.0)) * alpha, 255).to!ubyte;
        }
        xpos += (cd.advance * scale).to!int;
        //kerning
        //if (ci != text.length - 1) xpos += (stbtt_GetCodepointKernAdvance(&fontData.info, text[ci], text[ci + 1]) * scale).to!int;
    }
    return Texture(pixels, width, height);
}

private {
    // フォント名ごとにキャッシュ
    FontData[string] fontCache;
    FontData loadFont(string fontName) {
        if (!(fontName in fontCache)) fontCache[fontName] = new FontData(fontName);
        return fontCache[fontName];
    }

    class FontData {
        ubyte[] fileData;
        stbtt_fontinfo info;
        int ascent, descent, lineGap;

        this(string fontName) {
            fileData = cast(ubyte[])(read(fontName));
            stbtt_InitFont(&info, fileData.ptr, stbtt_GetFontOffsetForIndex(fileData.ptr, 0));
            stbtt_GetFontVMetrics(&info, &ascent, &descent, &lineGap);
        }

        // サイズ，文字ごとにキャッシュ(必要ある？)
        CharData[Tuple!(int, dchar)] charCache;
        CharData loadChar(int ptSize, dchar dc) {
            Tuple!(int, dchar) key = tuple(ptSize, dc);
            if (!(key in charCache)) charCache[key] = new CharData(ptSize, dc, info);
            return charCache[key];
        }
    }

    class CharData {
        ubyte* bitmap;
        int w, h, xoff, yoff;
        int advance, lsb;

        this(int ptSize, dchar dc, stbtt_fontinfo info) {
            float scale = stbtt_ScaleForPixelHeight(&info, ptSize);
            bitmap = stbtt_GetCodepointBitmap(&info, scale, scale, dc, &w, &h, &xoff, &yoff);
            stbtt_GetCodepointHMetrics(&info, dc, &advance, &lsb);
        }

        ~this() {
            stbtt_FreeBitmap(bitmap);
        }
    }
}
