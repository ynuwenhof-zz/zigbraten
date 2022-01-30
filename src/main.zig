const std = @import("std");
const windows = std.os.windows;
const kernel32 = windows.kernel32;

const BOOL = windows.BOOL;
const DWORD = windows.DWORD;
const LPVOID = windows.LPVOID;
const HMODULE = windows.HMODULE;
const HINSTANCE = windows.HINSTANCE;

const dll_process_attach = 1;

extern "kernel32" fn DisableThreadLibraryCalls(hLibModule: HMODULE) callconv(WINAPI) BOOL;

pub export fn DllMain(hinst_dll: HINSTANCE, fdw_reason: DWORD, _: LPVOID) BOOL {
    switch (fdw_reason) {
        dll_process_attach => {
            _ = DisableThreadLibraryCalls(@ptrCast(HMODULE, hinst_dll));

            const optional_handle = kernel32.CreateThread(null, 0, entry, hinst_dll, 0, null);
            if (optional_handle) |handle| {
                _ = kernel32.CloseHandle(handle);
            }
        },
        else => {},
    }

    return 1;
}

export fn entry(_: *anyopaque) DWORD {
    return 0;
}
