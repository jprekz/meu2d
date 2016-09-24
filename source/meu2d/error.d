module meu2d.error;

import std.exception;
import core.stdc.string;

import derelict.sdl2.sdl;



@trusted string getSDLErrorMessage() {
    if(auto msg = SDL_GetError()) {
        return msg[0 .. strlen(msg)].idup;
    } else {
        return null;
    }
}

T enforceSDL(T)(T value, string file = __FILE__, size_t line = __LINE__) {
    static if (is(T == int))
        return enforce(value == 0, getSDLErrorMessage(), file, line);    // ?
    else
        return enforce(value, getSDLErrorMessage(), file, line);
}
