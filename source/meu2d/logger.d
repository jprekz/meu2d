module meu2d.logger;

import std.conv : to;
import std.typecons : Nullable;

import meu2d.core;
import meu2d.draw;

import std.experimental.logger;



public class MeuLogger : Logger {
    private GameObject mlgo;
    private string[] strs;
    
    public GameObject getGameObject() {
        return mlgo;
    }
    
    this(int ptSize, string fontName) {
        super(LogLevel.all);
        mlgo = new MeuLoggerGameObject(this, ptSize, fontName);
    }

    override void writeLogMsg(ref LogEntry payload) {
        strs ~= payload.msg;
    }
}

private class MeuLoggerGameObject : GameObject {
    private MeuLogger meulogger;
    immutable private int ptsize;
    immutable private string fontname;
    immutable private int max = 10;

    // circular buffer
    private Nullable!Texture[10] texts;
    private int ptr = 0;

    this(MeuLogger ml, int ptSize, string fontName) {
        meulogger = ml;
        ptsize = ptSize;
        fontname = fontName;
    }

    override void update() {
        if (meulogger.strs.length) {
            foreach (str; meulogger.strs) {
                texts[ptr] = renderText(str.to!dstring, ptsize, fontname, Color(255, 255, 255, 128));
                if (++ptr >= max) ptr = 0;
            }
            meulogger.strs = [];
        }
    }

    override void draw() {
        int y = 0;
        foreach (i; 0 .. max) {
            if (!texts[ptr].isNull) texts[ptr].draw(0, y++ * ptsize);
            if (++ptr >= max) ptr = 0;
        }
    }
}
