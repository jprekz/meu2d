module meu2d.core;

import std.string;
import std.container;
import std.range;

import std.conv;

import derelict.sdl2.sdl;

import meu2d.error;
import meu2d.input;
import meu2d.logger;

static this() {
    DerelictSDL2.load();
}

static ~this() {
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

/// meu2dフレームワークを初期化し，ウィンドウを表示します。
/// params:
///     width  = ウィンドウの幅
///     height = ウィンドウの高さ
///     title  = ウィンドウのタイトル
void init(int width, int height, string title, WindowStatus ws = WindowStatus.fixed) {
    SDL_Init(SDL_INIT_EVERYTHING).enforceSDL;

    const flags = SDL_WINDOW_SHOWN |
        (ws == WindowStatus.resizable) ? SDL_WINDOW_RESIZABLE :
        (ws == WindowStatus.maximized) ? (SDL_WINDOW_RESIZABLE | SDL_WINDOW_MAXIMIZED) : 0;
    window = SDL_CreateWindow(
            toStringz(title),
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            flags).enforceSDL;
    Window.width = width;
    Window.height = height;

    renderer = SDL_CreateRenderer(
            window,
            -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC).enforceSDL;

    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    
    class GlobalGameObject : GameObject {
        override void draw() {
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255).enforceSDL;
            SDL_RenderClear(renderer).enforceSDL;
        }
    }
    _global = new GlobalGameObject();
}

enum WindowStatus {
    fixed, resizable, maximized
}

/// meu2dフレームワークによる処理を開始します。
void start() {
    immutable uint FPS = 60;
    immutable uint interval = 1000 / FPS;
    uint nextTime = SDL_GetTicks() + interval;
    bool skipDraw = false;

    mainLoop:while(true) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch(event.type) {
                case SDL_WINDOWEVENT: {
                    switch (event.window.event)  {
                        case SDL_WINDOWEVENT_SIZE_CHANGED:  {
                            Window.width = event.window.data1;
                            Window.height = event.window.data2;
                            break;
                        }
                        default: break;
                    }
                    break;
                }

                case SDL_MOUSEWHEEL: {
                    Mouse.wheelX = event.wheel.x;
                    Mouse.wheelY = event.wheel.y;
                    break;
                }

                case SDL_QUIT: {
                    break mainLoop;
                }
                default: break;
            }
        }
        updateMouseState();

        allUpdate();
        if (!skipDraw) {
            allDraw();
            SDL_RenderPresent(renderer);
        }

        resetMouseWheel();

        //adjust FPS
        int delayTime = nextTime - SDL_GetTicks();
        if (delayTime > 0) {
            SDL_Delay(delayTime);
            skipDraw = false;
        } else {
            skipDraw = true;
        }
        nextTime += interval;
    }
}

/// meu2dフレームワークが処理するオブジェクトが継承する抽象クラスです。
abstract class GameObject {
    void update() {}
    void draw() {}

    final void add(GameObject o, int zindex = 0) {
        o.zIndex = zindex;
        auto a = children[];
        while(true) {
            if (a.empty) {
                children.insertFront(o);
                return;
            }
            if (a.front.zIndex <= zindex) {
                a.popBack();
                children.insertAfter(a, o);
                return;
            }
            a.popFront();
        }
    }

    private DList!GameObject children;
    private int zIndex;
}

GameObject global() {
    return _global;
}

struct Window {
    static int width, height;
}



package {
    SDL_Window* window;
    SDL_Renderer* renderer;
}

private {
    GameObject _global;

    void allUpdate(GameObject o = _global) {
        o.update();
        foreach (child; o.children) {
            allUpdate(child);
        }
    }

    void allDraw(GameObject o = _global) {
        o.draw();
        foreach (child; o.children) {
            allDraw(child);
        }
    }
}
