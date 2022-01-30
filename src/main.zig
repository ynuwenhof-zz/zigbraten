const std = @import("std");
const windows = std.os.windows;

const BOOL = windows.BOOL;
const DWORD = windows.DWORD;
const LPVOID = windows.LPVOID;
const HINSTANCE = windows.HINSTANCE;

const dll_process_attach = 1;

pub export fn DllMain(_: HINSTANCE, fdw_reason: DWORD, _: LPVOID) BOOL {
    switch (fdw_reason) {
        dll_process_attach => {},
        else => {},
    }

    return 1;
}
