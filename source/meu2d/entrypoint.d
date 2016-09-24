module meu2d.entrypoint;



/// Windows環境において，ビルドが成功しない・プログラムの実行時に不安定になるといった不具合が起こる場合に使用します。
mixin template gameMain(alias entry) {
    version(Windows) {
        import std.string;
        import core.runtime;
        import core.sys.windows.windows;

        extern (Windows)
        int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
            try {
                Runtime.initialize();
                entry();
                Runtime.terminate();
            } catch (Throwable e) {
                MessageBoxA(null, e.toString.toStringz, null, MB_ICONEXCLAMATION);
            }
            return 0;
        }
    } else {
        void main() {
            entry();
        }
    }
}
