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

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn distance(self: Vec3, other: Vec3) f32 {
        return math.sqrt(
            math.pow(f32, other.x - self.x, 2.0) +
            math.pow(f32, other.y - self.y, 2.0) +
            math.pow(f32, other.z - self.z, 2.0)
        );
    }

    pub fn angle(self: Vec3, other: Vec3) Vec3 {
        return Vec3 {
            .x = -math.atan2(f32, other.x - self.x, other.y - self.y) / math.pi * 180.0,
            .y = math.asin((other.z - self.z) / self.distance(other)) * 180.0 / math.pi,
            .z = 0.0,
        };
    }
};

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
