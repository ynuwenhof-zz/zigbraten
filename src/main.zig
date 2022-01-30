const std = @import("std");
const math = std.math;
const windows = std.os.windows;
const kernel32 = windows.kernel32;

const INT = windows.INT;
const BOOL = windows.BOOL;
const CHAR = windows.CHAR;
const SHORT = windows.SHORT;
const DWORD = windows.DWORD;
const WINAPI = windows.WINAPI;
const LPVOID = windows.LPVOID;
const HMODULE = windows.HMODULE;
const HINSTANCE = windows.HINSTANCE;

const vk_r_shift = 0xA1;
const dll_process_attach = 1;

extern "user32" fn GetAsyncKeyState(vKey: INT) callconv(WINAPI) SHORT;
extern "kernel32" fn DisableThreadLibraryCalls(hLibModule: HMODULE) callconv(WINAPI) BOOL;

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn distance(self: Vec3, other: Vec3) f32 {
        return math.sqrt(math.pow(f32, other.x - self.x, 2.0) +
            math.pow(f32, other.y - self.y, 2.0) +
            math.pow(f32, other.z - self.z, 2.0));
    }

    pub fn angle(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = -math.atan2(f32, other.x - self.x, other.y - self.y) / math.pi * 180.0,
            .y = math.asin((other.z - self.z) / self.distance(other)) * 180.0 / math.pi,
            .z = 0.0,
        };
    }
};

const Entity = struct {
    pad_0000: [48]CHAR,
    pos: Vec3,
    angle: Vec3,
    pad_0048: [47]CHAR,
    is_dead: bool,
    pad_0078: [280]CHAR,
    delay: i32,
    pad_0194: [788]CHAR,
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
    const base_addr = @ptrToInt(kernel32.GetModuleHandleW(null).?);
    const local_entity = @intToPtr(**Entity, (base_addr + 0x002A3528)).*;
    const entity_list = @intToPtr(*u64, (base_addr + 0x346C90));
    const entity_list_count = @intToPtr(*i32, (base_addr + 0x3472EC));

    var enabled = false;
    while (true) {
        if ((GetAsyncKeyState(vk_r_shift) & 1) != 0) {
            enabled = !enabled;
        }

        if (!enabled or local_entity.*.is_dead) continue;

        var optional_target: ?*Entity = null;
        var lowest_coefficient: f32 = math.f32_max;

        var i: usize = 0;
        while (i < entity_list_count.*) {
            const entity = @intToPtr(**Entity, entity_list.* + i * 0x08).*;
            if (entity.*.is_dead) continue;

            const angle = local_entity.*.pos.angle(entity.*.pos).distance(local_entity.*.angle);
            const distance = local_entity.*.pos.distance(entity.*.pos);
            const coefficient = distance * 0.3 + angle * 0.7;

            if (coefficient < lowest_coefficient) {
                lowest_coefficient = coefficient;
                optional_target = entity;
            }

            i += 1;
        }

        if (optional_target) |target| {
            local_entity.*.angle = local_entity.*.pos.angle(target.*.pos);
        }
    }
}
