module meu2d.input;

import derelict.sdl2.sdl;

import meu2d.core;

struct Mouse {
    static int x, y;
    static bool L, M, R;
}

package void updateMouseState() {
    uint buttons = SDL_GetMouseState(&Mouse.x, &Mouse.y);
    Mouse.L = (buttons & SDL_BUTTON(1)) != 0;
    Mouse.M = (buttons & SDL_BUTTON(2)) != 0;
    Mouse.R = (buttons & SDL_BUTTON(3)) != 0;
}

struct Key(string k) {
    static bool isPressed() {
        SDL_Scancode code = mixin("SDL_SCANCODE_" ~ k);
        auto a = SDL_GetKeyboardState(null);
        return a[code] != 0;
    }
    alias isPressed this;
}
