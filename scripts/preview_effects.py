"""Offline review of the drift and boost effects as the addon's own UI draws them.

python scripts/preview_effects.py [--out docs/art/effects/drift-boost-review.png]

Runs the real addon Lua (pinned Lupa, Lua 5.1) against a minimal recording
mock of the WoW widget API, drives a scripted Mirage run (throttle, a left
drift through both charge tiers, release into a boost, then a right drift),
and composites every shown canvas texture in draw-layer order: the cropped
background, track markers, smoke, sparks, the kart sheet frame and the
exhaust flames, using the runtime TGAs, crops, sizes and vertex colors.

This is a review picture, not client evidence: WoW's own filtering, blending
and pixel snapping are not reproduced, and nothing here proves that the
client loads or draws the files.
"""
import argparse
import importlib
import os
from math import floor
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintkit import decode_tga, encode_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
MODULES = ("Track", "MirageRaceway", "Physics", "Input", "Loop", "Performance", "Presentation",
           "Checkpoints", "Laps", "Race", "UI", "NetworkProbe", "TransportProbe", "Core")

MOCK = r"""
local methods = {}
mock = {textures = {}, frames = {}}
local function object()
    return setmetatable({shown = true, scripts = {}, events = {}}, {
        __index = function(_, key) return methods[key] or function() end end})
end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:IsShown() return self.shown end
function methods:Show()
    if self.shown then return end
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    if not self.shown then return end
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:IsEnabled() return self.enabled ~= false end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetAllPoints(relative) self.all = relative end
function methods:SetColorTexture(r, g, b, a) self.color, self.path = {r, g, b, a or 1}, nil end
function methods:SetTexture(path) self.path, self.color = path, nil; return true end
function methods:SetVertexColor(r, g, b, a) self.tint = {r, g, b, a or 1} end
function methods:SetTexCoord(l, r, t, b) self.uv = {l, r, t, b} end
function methods:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel or 0 end
function methods:CreateTexture(_, layer)
    local item = object()
    item.parent, item.layer, item.sublevel = self, layer, 0
    mock.textures[#mock.textures + 1] = item
    item.index = #mock.textures
    return item
end
function methods:CreateFontString() return object() end
CreateFrame = function(_, name, parent)
    local frame = object()
    frame.parent = parent
    mock.frames[#mock.frames + 1] = frame
    return frame
end
UIParent = {}
InCombatLockdown = function() return false end
GetCurrentKeyBoardFocus = function() return nil end
IsGameWindowFocused = function() return true end
GetBuildInfo = function() return "mock", "0", "preview", 16001 end
GetFramerate = function() return 60 end
GetTime = function() return 0 end
debugprofilestop = function() return 0 end
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
SlashCmdList = {}
print = function() end

function mock.load(names)
    local namespace = {}
    for _, name in ipairs(names) do
        assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", namespace)
    end
    for _, frame in ipairs(mock.frames) do
        if frame.events.ADDON_LOADED and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, "ADDON_LOADED", "AzerothKart")
        end
    end
    mock.UI = namespace.UI
    return namespace.UI
end

function mock.key(script, key) mock.UI.window.scripts[script](mock.UI.window, key) end

-- One line per shown canvas texture: index|layer|sublevel|source|uv|point|size|tint
function mock.snapshot()
    local lines, canvas = {}, mock.UI.canvas
    for _, item in ipairs(mock.textures) do
        local get = function(key) return rawget(item, key) end
        if item.parent == canvas and item.shown and (get("point") or get("all")) then
            local source = get("path") or (get("color") and table.concat(get("color"), " ")) or "none"
            local uv = get("uv") and table.concat(get("uv"), " ") or "0 1 0 1"
            local point = get("all") and "ALL 0 0" or
                (get("point")[1] .. " " .. get("point")[4] .. " " .. get("point")[5])
            local size = get("all") and "800 480" or ((get("width") or 0) .. " " .. (get("height") or 0))
            local tint = get("tint") and table.concat(get("tint"), " ") or "1 1 1 1"
            lines[#lines + 1] = table.concat({item.index, item.layer, item.sublevel, source, uv, point, size, tint}, "|")
        end
    end
    return table.concat(lines, "\n")
end
"""

LAYERS = {"BACKGROUND": 0, "BORDER": 1, "ARTWORK": 2, "OVERLAY": 3}
WIDTH, HEIGHT = 800, 480


def load_texture(path, cache):
    if path not in cache:
        relative = path.replace("Interface\\AddOns\\AzerothKart\\", "").replace("\\", "/")
        _, px = decode_tga((ADDON / relative).read_bytes())
        cache[path] = px
    return cache[path]


def sample(px, u, v):
    """Straight-alpha bilinear fetch, texture coordinates in [0, 1] from the top-left."""
    h, w = len(px), len(px[0])
    fx, fy = u * w - 0.5, v * h - 0.5
    x0, y0 = int(floor(fx)), int(floor(fy))
    tx, ty = fx - x0, fy - y0
    out = [0.0, 0.0, 0.0, 0.0]
    for dy, wy in ((0, 1.0 - ty), (1, ty)):
        for dx, wx in ((0, 1.0 - tx), (1, tx)):
            texel = px[min(max(y0 + dy, 0), h - 1)][min(max(x0 + dx, 0), w - 1)]
            for c in range(4):
                out[c] += texel[c] * wx * wy
    return out


def composite(snapshot, cache):
    image = [[[0.0, 0.0, 0.0] for _ in range(WIDTH)] for _ in range(HEIGHT)]
    items = []
    for line in snapshot.splitlines():
        index, layer, sublevel, source, uv, point, size, tint = line.split("|")
        items.append((LAYERS[layer], int(float(sublevel)), int(index), source, [float(x) for x in uv.split()],
                      point.split(), [float(x) for x in size.split()], [float(x) for x in tint.split()]))
    items.sort(key=lambda item: item[:3])
    for _, _, _, source, uv, point, size, tint in items:
        width, height = size
        anchor, x, y = point[0], float(point[1]), float(point[2])
        if anchor == "CENTER":
            left, bottom = x - width / 2, y - height / 2
        else:
            left, bottom = x, y
        if width <= 0 or height <= 0:
            continue
        solid = None if source.startswith("Interface") else [float(v) for v in source.split()]
        px = None if solid else load_texture(source, cache)
        x0, x1 = max(0, int(floor(left))), min(WIDTH, int(floor(left + width)) + 1)
        y0, y1 = max(0, int(floor(bottom))), min(HEIGHT, int(floor(bottom + height)) + 1)
        for cy in range(y0, y1):
            fy = (cy + 0.5 - bottom) / height
            if not 0.0 <= fy < 1.0:
                continue
            row = image[HEIGHT - 1 - cy]
            for cx in range(x0, x1):
                fx = (cx + 0.5 - left) / width
                if not 0.0 <= fx < 1.0:
                    continue
                if solid:
                    rgb, a = solid[:3], solid[3]
                else:
                    u = uv[0] + (uv[1] - uv[0]) * fx
                    v = uv[2] + (uv[3] - uv[2]) * (1.0 - fy)
                    r, g, b, a = sample(px, u, v)
                    rgb, a = [r / 255.0 * tint[0], g / 255.0 * tint[1], b / 255.0 * tint[2]], a / 255.0 * tint[3]
                if a <= 0.0:
                    continue
                pixel = row[cx]
                for c in range(3):
                    pixel[c] = rgb[c] * a + pixel[c] * (1.0 - a)
    return image


def crop(image, cx, cy, width, height, zoom):
    left, top = int(cx - width / 2), int(HEIGHT - cy - height / 2)
    left, top = max(0, min(WIDTH - width, left)), max(0, min(HEIGHT - height, top))
    out = []
    for y in range(height * zoom):
        src = image[top + y // zoom]
        out.append([[int(min(1.0, src[left + x // zoom][c]) * 255.0 + 0.5) for c in range(3)] + [255]
                    for x in range(width * zoom)])
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=ROOT / "docs" / "art" / "effects" / "drift-boost-review.png")
    args = parser.parse_args()
    local_deps = ROOT / "local-artifacts" / "python-deps"
    if local_deps.is_dir():
        sys.path.insert(0, str(local_deps))
    os.chdir(ROOT)
    lua = importlib.import_module("lupa.lua51").LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    mock = lua.globals().mock
    names = lua.table(*MODULES)
    ui = mock.load(names)
    ui.Toggle()
    assert ui.SelectTrack("mirage_raceway"), "Mirage selection refused"
    ui.Start()
    mock.key("OnKeyDown", "W")
    # Ticks to capture, with the reason; the drive follows tests/test_ui.lua's script.
    captures = {352: "charging", 378: "tier 1", 408: "tier 2", 418: "boost fires", 428: "boosting",
                612: "right drift, tier 2", 626: "boost, other side"}
    script = [(340, "OnKeyDown", "A"), (340, "OnKeyDown", "SPACE"), (415, "OnKeyUp", "SPACE"),
              (450, "OnKeyUp", "A"), (548, "OnKeyDown", "D"), (548, "OnKeyDown", "SPACE"),
              (622, "OnKeyUp", "SPACE"), (650, "OnKeyUp", "D")]
    shots, cache, done = [], {}, set()
    for _ in range(2000):
        tick = ui.state.tick
        for at, script_name, key in script:
            if tick >= at and (at, key, script_name) not in done:
                done.add((at, key, script_name))
                mock.key(script_name, key)
        ui.OnUpdate(1 / 60)
        if ui.state.tick in captures and ui.state.tick not in [s[0] for s in shots]:
            snapshot = mock.snapshot()
            kart = [line for line in snapshot.splitlines() if "Karts" in line][0].split("|")
            kx, ky = float(kart[5].split()[1]), float(kart[5].split()[2])
            shots.append((ui.state.tick, captures[ui.state.tick], composite(snapshot, cache), kx, ky,
                          bool(ui.state.drifting), int(ui.state.driftTier), int(ui.state.boostTicks)))
        if len(shots) == len(captures) or not ui.active:
            break
    assert len(shots) == len(captures), f"captured {len(shots)} of {len(captures)} frames"
    cw, ch, zoom, gap = 200, 140, 2, 6
    columns = 4
    rows = (len(shots) + columns - 1) // columns
    sheet = [[[24, 24, 28, 255] for _ in range(gap + columns * (cw * zoom + gap))]
             for _ in range(gap + rows * (ch * zoom + gap))]
    for n, (tick, label, image, kx, ky, drifting, tier, boost) in enumerate(shots):
        tile = crop(image, kx, ky, cw, ch, zoom)
        ox, oy = gap + (n % columns) * (cw * zoom + gap), gap + (n // columns) * (ch * zoom + gap)
        for y, row in enumerate(tile):
            sheet[oy + y][ox:ox + len(row)] = row
        print(f"tile {n + 1}: tick {tick} {label}: drifting={drifting} tier={tier} boostTicks={boost}")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(encode_png(sheet))
    print(f"PREVIEW: {args.out.resolve().as_posix()}")


if __name__ == "__main__":
    main()
