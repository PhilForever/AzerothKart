"""Offline layout review of the Azeroth Kart window and its menus.

python scripts/preview_ui.py [--out docs/art/ui/front-end-review.png] [--screens DIR]
    [--race-out docs/art/ui/race-screens-review.png] [--client-fonts DIR] [--check]

Runs the real addon Lua (pinned Lupa, Lua 5.1) against a recording mock of the
widget API, visits every screen (main menu, track and kart choice, garage,
multiplayer, help, settings, a race and its results, the results' celebrations
and a two-player race and its results on stand-in data), solves each widget's
anchors the way the client does, and draws the result: the addon's own TGAs
for the track, kart, effects and previews, and simple stand-ins for the
client's dialog backdrops, buttons, check buttons, header and fonts.

This is a layout picture, not client evidence or a screenshot: the client's
real button and border art, its filtering and pixel snapping are not
reproduced. Its fonts are stand-ins (Bitstream Charter for Friz Quadrata,
FreeSerif for Morpheus) unless --client-fonts names a folder holding the
client's own frizqt__.ttf and morpheus.ttf (extracted from the owner's install
by scripts/wowcasc.py into local-artifacts/, never committed). Either way the
client draws Friz Quadrata about 13% wider than its nominal size (EM below,
measured on the owner's 2026-10-29 screenshot of the track screen: every line
of Arathi Basin's copy wraps where the client wraps it), so text measures and
wraps as in the client.

--check walks every menu screen with every track and every kart chosen (the
track and kart screens, the garage, the board for every track) and reports
any visible text or control that overlaps another control or text in the same
dialog, text cut short or hidden under a card drawn over it, or a control
leaving its dialog; it exits 1 when it finds one. With --check the review
pictures are written only where --out, --race-out or --screens ask (a check
changes no tracked file). About five seconds. Needs Pillow.
"""
import argparse
import importlib
import os
import re
import sys
from math import degrees
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "AzerothKart"
# The addon's files, in the TOC's order, as the client loads them.
MODULES = tuple(line.strip()[:-4] for line in (ADDON / "AzerothKart_Camelot.toc").read_text().splitlines()
                if not line.startswith("##") and line.strip().endswith(".lua"))
FONTS = {  # client font object -> (face, pixel height, default colour, outline)
    "GameFontNormal": ("friz", 12, (1, .82, 0), False), "GameFontHighlight": ("friz", 12, (1, 1, 1), False),
    "GameFontDisable": ("friz", 12, (.5, .5, .5), False), "GameFontRed": ("friz", 12, (1, .1, .1), False),
    "GameFontNormalSmall": ("friz", 10, (1, .82, 0), False), "GameFontHighlightSmall": ("friz", 10, (1, 1, 1), False),
    "GameFontDisableSmall": ("friz", 10, (.5, .5, .5), False), "GameFontGreenSmall": ("friz", 10, (.1, 1, .1), False),
    "GameFontNormalLarge": ("friz", 16, (1, .82, 0), False), "GameFontHighlightLarge": ("friz", 16, (1, 1, 1), False),
    "GameFontDisableLarge": ("friz", 16, (.5, .5, .5), False), "GameFontNormalHuge": ("friz", 20, (1, .82, 0), False),
    "GameFontNormalHuge2": ("friz", 24, (1, .82, 0), False), "GameFontNormalHuge3": ("friz", 25, (1, .82, 0), False),
    "GameFontNormalHuge3Outline": ("friz", 25, (1, .82, 0), True),
    "GameFontHighlightHuge": ("friz", 20, (1, 1, 1), False), "GameFontHighlightHuge2": ("friz", 24, (1, 1, 1), False),
    "Fancy48Font": ("morpheus", 48, (1, 1, 1), False), "Fancy32Font": ("morpheus", 32, (1, 1, 1), False),
    "Game72Font": ("friz", 72, (1, 1, 1), False), "Game48Font": ("friz", 48, (1, 1, 1), False),
    "Game42Font": ("friz", 42, (1, 1, 1), False), "Game36Font": ("friz", 36, (1, 1, 1), False),
    "GameFontHighlightSmallOutline": ("friz", 10, (1, 1, 1), True),
}
FACES = {"friz": "/usr/share/fonts/type1/texlive-fonts-recommended/bchb8a.pfb",
         "morpheus": "/usr/share/fonts/truetype/freefont/FreeSerifBold.ttf"}
CLIENT_FACES = {"friz": "frizqt__.ttf", "morpheus": "morpheus.ttf"}
# The client's glyphs against the nominal size (the line pitch stays the size):
# Friz Quadrata 1.13 times wider (both it and the Charter stand-in then wrap
# Arathi Basin's blurb and facts line for line as the client did); Morpheus
# titles measured at their size.
EM = {"friz": 1.13, "morpheus": 1.0}
LAYERS = {"BACKGROUND": 0, "BORDER": 1, "ARTWORK": 2, "OVERLAY": 3, "HIGHLIGHT": 4}
SCREEN_W, SCREEN_H = 900, 830

MOCK = r"""
local methods = {}
mock = {objects = {}}
local function object(kind, parent)
    local o = setmetatable({kind = kind, parent = parent, shown = true, scripts = {}, events = {}, points = {}},
        {__index = function(_, key) return methods[key] or function() end end})
    mock.objects[#mock.objects + 1] = o
    o.index = #mock.objects
    return o
end
function mock.level(o)
    if rawget(o, "level") then return o.level end
    if rawget(o, "parent") then return mock.level(o.parent) + 1 end
    return 0
end
function methods:SetScript(name, fn) self.scripts[name] = fn end
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
function methods:Enable() self.disabled = false end
function methods:Disable() self.disabled = true end
function methods:IsEnabled() return not self.disabled end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 0 end
function methods:SetPoint(point, a, b, c, d)
    local rel, relPoint, x, y
    if type(a) == "table" then rel, relPoint, x, y = a, b, c, d
    elseif type(a) == "number" then x, y = a, b end
    self.points[#self.points + 1] = {point, rel or self.parent, relPoint or point, x or 0, y or 0}
end
function methods:ClearAllPoints() self.points = {} end
function methods:SetAllPoints(rel)
    rel = rel or self.parent
    self.points = {{"TOPLEFT", rel, "TOPLEFT", 0, 0}, {"BOTTOMRIGHT", rel, "BOTTOMRIGHT", 0, 0}}
end
function methods:SetColorTexture(r, g, b, a) self.color, self.path = {r, g, b, a or 1}, nil end
function methods:SetTexture(path)
    if type(path) ~= "string" then return false end
    self.path, self.color = path, nil
    return true
end
function methods:SetVertexColor(r, g, b, a) self.tint = {r, g, b, a or 1} end
function methods:SetTexCoord(l, r, t, b) self.uv = {l, r, t, b} end
function methods:SetRotation(value) self.rotation = value end
function methods:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel or 0 end
function methods:CreateTexture(_, layer)
    local t = object("texture", self)
    t.layer, t.sublevel = layer or "ARTWORK", 0
    return t
end
function methods:CreateFontString(_, layer, font)
    local f = object("font", self)
    f.layer, f.sublevel, f.font = layer or "OVERLAY", 0, font or "GameFontNormal"
    return f
end
function methods:SetFontObject(font) if type(font) == "table" then self.font = font.name end end
function methods:SetTextColor(r, g, b, a) self.textColor = {r, g, b, a or 1} end
function methods:SetJustifyH(value) self.justify = value end
function methods:SetSpacing(value) self.spacing = value end
function methods:SetMaxLines(value) self.maxLines = value end
function methods:SetWordWrap(value) self.wordWrap = value end
function methods:SetBackdrop(info) self.backdrop = info; return true end
function methods:SetBackdropColor(r, g, b, a) self.backdropColor = {r, g, b, a or 1} end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return mock.level(self) end
function methods:LockHighlight() self.locked = true end
function methods:UnlockHighlight() self.locked = false end
function methods:SetChecked(value) self.checked = value end
function methods:Setup(text) self.headerText = text end
function methods:SetNormalFontObject(font) if type(font) == "table" then self.normalFont = font.name end end
CreateFrame = function(kind, name, parent, template)
    local f = object("frame", parent)
    f.frameKind, f.template = kind, template
    if kind == "Button" or kind == "CheckButton" then f.disabled = false end
    return f
end
UIParent = object("frame", nil)
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
AzerothKartDB = nil

function mock.load(names, fonts)
    for _, name in ipairs(fonts) do _G[name] = {name = name} end
    local namespace = {}
    for _, name in ipairs(names) do
        assert(loadfile("addon/AzerothKart/" .. name .. ".lua"))("AzerothKart", namespace)
    end
    for _, o in ipairs(mock.objects) do
        if o.events.ADDON_LOADED and o.scripts.OnEvent then o.scripts.OnEvent(o, "ADDON_LOADED", "AzerothKart") end
    end
    mock.namespace = namespace
    return namespace.UI
end

function mock.key(script, key) mock.namespace.UI.window.scripts[script](mock.namespace.UI.window, key) end
function mock.step(ticks) for _ = 1, ticks do mock.namespace.UI.OnUpdate(1 / 60) end end

-- A finished three-lap run with believable lap times: drive between gates,
-- then place the kart just before each gate (as the UI tests do).
function mock.finish(lapTicks)
    local UI = mock.namespace.UI
    local Track = UI.track                     -- the selected course's gates
    UI.Start()
    mock.step(180)
    mock.key("OnKeyDown", "W")
    for lap = 1, 3 do
        for index, gate in ipairs(Track.gates) do
            mock.step(math.floor(lapTicks[lap] / 4) - 1)
            UI.state.x = (gate.ax + gate.bx) / 2 - gate.nx
            UI.state.y = (gate.ay + gate.by) / 2 - gate.ny
            UI.state.heading = gate.nx == 1 and 0 or gate.nx == -1 and math.pi or
                gate.ny == 1 and math.pi / 2 or -math.pi / 2
            UI.state.speed, UI.state.steering = 200, 0
            UI.OnUpdate(1 / 60)
            if not UI.active then return end
        end
    end
end

function mock.dump()
    local out = {}
    local function ref(o) return type(o) == "table" and rawget(o, "index") or 0 end
    for i, o in ipairs(mock.objects) do
        local points = {}
        for j, p in ipairs(o.points) do points[j] = {p[1], ref(p[2]), p[3], p[4], p[5]} end
        local visible, walk = true, o
        while walk do
            if not walk.shown then visible = false end
            walk = rawget(walk, "parent")
        end
        out[i] = {kind = o.kind, parent = ref(rawget(o, "parent")), points = points, width = rawget(o, "width"),
            height = rawget(o, "height"), visible = visible, level = mock.level(o), text = rawget(o, "text"),
            font = rawget(o, "font"), textColor = rawget(o, "textColor"), justify = rawget(o, "justify"),
            spacing = rawget(o, "spacing"), layer = rawget(o, "layer"), sublevel = rawget(o, "sublevel"),
            color = rawget(o, "color"), path = rawget(o, "path"), uv = rawget(o, "uv"), tint = rawget(o, "tint"),
            rotation = rawget(o, "rotation"), template = rawget(o, "template"), frameKind = rawget(o, "frameKind"),
            backdrop = rawget(o, "backdrop") and (rawget(o, "backdrop").edgeFile or "") .. "|" ..
                (rawget(o, "backdrop").bgFile or "") or nil,
            backdropColor = rawget(o, "backdropColor"), disabled = rawget(o, "disabled"),
            locked = rawget(o, "locked"), checked = rawget(o, "checked"), headerText = rawget(o, "headerText"),
            normalFont = rawget(o, "normalFont"), maxLines = rawget(o, "maxLines"), wordWrap = rawget(o, "wordWrap")}
    end
    return out
end
"""


def lua_list(value):
    return None if value is None else [value[i] for i in range(1, len(value) + 1)]


def snapshot(lua):
    raw = lua.eval("mock.dump()")
    objects = [None]
    for i in range(1, len(raw) + 1):
        o = raw[i]
        item = {key: o[key] for key in ("kind", "parent", "width", "height", "visible", "level", "text", "font",
                                        "justify", "spacing", "layer", "sublevel", "path", "rotation", "template",
                                        "frameKind", "backdrop", "disabled", "locked", "checked", "headerText",
                                        "normalFont", "maxLines", "wordWrap")}
        for key in ("textColor", "color", "uv", "tint", "backdropColor"):
            item[key] = lua_list(o[key])
        item["points"] = [lua_list(o["points"][j]) for j in range(1, len(o["points"]) + 1)]
        objects.append(item)
    return objects


def horizontal(point):
    return "LEFT" if "LEFT" in point else "RIGHT" if "RIGHT" in point else "CENTER"


def vertical(point):
    return "TOP" if point.startswith("TOP") else "BOTTOM" if point.startswith("BOTTOM") else "CENTER"


class Layout:
    def __init__(self, objects):
        self.objects, self.rects, self.fonts = objects, {}, {}

    def font(self, name):
        face, size, rgb, outline = FONTS.get(name or "GameFontNormal", FONTS["GameFontNormal"])
        key = (face, size)
        if key not in self.fonts:
            self.fonts[key] = ImageFont.truetype(FACES[face], size * EM[face])
        return self.fonts[key], size, rgb, outline

    def lines(self, item, width=None):
        text = re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", item["text"] or "")
        font, _, _, _ = self.font(item["font"])
        out = []
        for paragraph in text.split("\n"):
            if width is None:
                out.append(paragraph)
                continue
            if item.get("wordWrap") is False:
                # One line, cut with an ellipsis where it would overrun (as the client).
                line = paragraph
                if font.getlength(line) > width:
                    while line and font.getlength(line + "...") > width:
                        line = line[:-1]
                    line += "..."
                out.append(line)
                continue
            words, line = paragraph.split(" "), ""
            for word in words:
                trial = word if not line else line + " " + word
                if font.getlength(trial) <= width or not line:
                    line = trial
                else:
                    out.append(line)
                    line = word
            out.append(line)
        most = item.get("maxLines")
        if most and len(out) > most:
            out = out[:most]
            out[-1] = out[-1] + "..."
        return out

    def text_size(self, item):
        font, size, _, _ = self.font(item["font"])
        lines = self.lines(item, item["width"])
        width = item["width"] or max([font.getlength(line) for line in lines] + [0])
        spacing = item["spacing"] or 0
        return width, len(lines) * size + (len(lines) - 1) * spacing

    def rect(self, index):
        if index in self.rects:
            return self.rects[index]
        item = self.objects[index]
        if item["parent"] == 0 and item["kind"] == "frame" and not item["points"]:
            self.rects[index] = (0, 0, SCREEN_W, SCREEN_H)  # UIParent
            return self.rects[index]
        width, height = item["width"], item["height"]
        if item["kind"] == "font":
            width, height = self.text_size(item)
        left = right = cx = top = bottom = cy = None
        for point, relative, relative_point, x, y in item["points"]:
            l, b, r, t = self.rect(relative)
            h, v = horizontal(relative_point), vertical(relative_point)
            px = (l if h == "LEFT" else r if h == "RIGHT" else (l + r) / 2) + x
            py = (t if v == "TOP" else b if v == "BOTTOM" else (b + t) / 2) + y
            h, v = horizontal(point), vertical(point)
            if h == "LEFT": left = px
            elif h == "RIGHT": right = px
            else: cx = px
            if v == "TOP": top = py
            elif v == "BOTTOM": bottom = py
            else: cy = py
        width, height = width or 0, height or 0
        if left is not None and right is not None: pass
        elif left is not None: right = left + width
        elif right is not None: left = right - width
        elif cx is not None: left, right = cx - width / 2, cx + width / 2
        else: left, right = 0, width
        if top is not None and bottom is not None: pass
        elif top is not None: bottom = top - height
        elif bottom is not None: top = bottom + height
        elif cy is not None: bottom, top = cy - height / 2, cy + height / 2
        else: bottom, top = 0, height
        self.rects[index] = (left, bottom, right, top)
        return self.rects[index]


class Painter:
    def __init__(self, layout):
        self.layout = layout
        self.image = Image.new("RGBA", (SCREEN_W, SCREEN_H), (32, 36, 44, 255))
        self.textures = {}

    def box(self, rect):
        l, b, r, t = rect
        return [round(l), round(SCREEN_H - t), round(r), round(SCREEN_H - b)]

    def overlay(self):
        return Image.new("RGBA", self.image.size, (0, 0, 0, 0))

    def composite(self, layer):
        self.image = Image.alpha_composite(self.image, layer)

    def fill(self, rect, rgba, radius=0, outline=None, width=1):
        layer = self.overlay()
        ImageDraw.Draw(layer).rounded_rectangle(self.box(rect), radius=radius, fill=rgba, outline=outline, width=width)
        self.composite(layer)

    def backdrop(self, item, rect):
        edge, _, bg = item["backdrop"].partition("|")
        l, b, r, t = rect
        if "DialogBox" in edge:
            base = (6, 6, 7, 242) if "Dark" in bg else (14, 14, 16, 225)
            self.fill((l + 6, b + 6, r - 6, t - 6), base, radius=8)
            self.fill(rect, None, radius=12, outline=(96, 92, 82, 255), width=5)
            self.fill((l + 4, b + 4, r - 4, t - 4), None, radius=10, outline=(178, 146, 72, 255), width=2)
        else:
            color = item["backdropColor"] or [0, 0, 0, 1]
            rgba = tuple(round(c * 255) for c in color[:3]) + (round(color[3] * 255),)
            self.fill((l + 3, b + 3, r - 3, t - 3), rgba, radius=3)
            self.fill(rect, None, radius=5, outline=(150, 150, 150, 255), width=2)

    def button(self, item, rect):
        big = item["template"] == "MainMenuFrameButtonTemplate"
        if item["frameKind"] == "CheckButton":
            l, b, r, t = rect
            self.fill((l + 5, b + 5, r - 5, t - 5), (20, 20, 22, 255), radius=3, outline=(190, 160, 70, 255), width=2)
            if item["checked"]:
                layer = self.overlay()
                x0, y0, x1, y1 = self.box((l + 5, b + 5, r - 5, t - 5))
                ImageDraw.Draw(layer).line([(x0 + 4, y0 + 11), (x0 + 9, y1 - 5), (x1 - 3, y0 + 4)],
                                           fill=(255, 210, 30, 255), width=4)
                self.composite(layer)
            return
        if item["disabled"]:
            fill, edge = (58, 58, 60, 255), (110, 110, 110, 255)
        elif item["locked"]:
            fill, edge = (170, 40, 20, 255), (255, 214, 90, 255)
        else:
            fill, edge = (128, 22, 12, 255), (196, 160, 80, 255)
        self.fill(rect, fill, radius=8 if big else 4, outline=edge, width=2)
        if item["text"]:
            large = big or (item["normalFont"] or "").endswith("Large")
            if item["disabled"]:
                font = "GameFontDisableLarge" if large else "GameFontDisable"
            elif item["locked"] or big:
                font = "GameFontHighlightLarge" if large else "GameFontHighlight"
            else:
                font = item["normalFont"] or "GameFontNormal"
            self.text(dict(item, font=font, textColor=None, justify="CENTER", width=None), rect, center=True)

    def header(self, item, rect):
        font, _, _, _ = self.layout.font("GameFontNormal")
        width = font.getlength(item["headerText"] or "") + 64
        l, b, r, t = rect
        cx = (l + r) / 2
        box = (cx - width / 2, t - 39, cx + width / 2, t)
        self.fill(box, (70, 66, 60, 255), radius=10, outline=(200, 168, 84, 255), width=2)
        self.text({"text": item["headerText"], "font": "GameFontNormal", "textColor": None, "justify": "CENTER",
                   "width": None, "spacing": 0}, (box[0], box[3] - 26, box[2], box[3] - 13), center=True)

    def texture(self, item, rect):
        l, b, r, t = rect
        if r - l < 1 or t - b < 1 or item["layer"] == "HIGHLIGHT":
            return                                  # a highlight shows only under the mouse
        x0, y0, x1, y1 = self.box(rect)
        size = (max(1, x1 - x0), max(1, y1 - y0))
        if item["color"]:
            c = item["color"]
            tile = Image.new("RGBA", size, tuple(round(v * 255) for v in c[:3]) + (round(c[3] * 255),))
        elif item["path"]:
            path = item["path"]
            if not path.startswith("Interface\\AddOns\\AzerothKart\\"):
                return
            if path not in self.textures:
                file = ADDON / path.replace("Interface\\AddOns\\AzerothKart\\", "").replace("\\", "/")
                self.textures[path] = Image.open(file).convert("RGBA")
            source = self.textures[path]
            u0, u1, v0, v1 = item["uv"] or [0, 1, 0, 1]
            w, h = source.size
            crop = source.crop((round(u0 * w), round(v0 * h), round(u1 * w), round(v1 * h)))
            tile = crop.resize(size, Image.BILINEAR)
            if item["tint"]:
                tr, tg, tb, ta = item["tint"]
                red, green, blue, alpha = tile.split()
                tile = Image.merge("RGBA", (red.point(lambda v: v * tr), green.point(lambda v: v * tg),
                                            blue.point(lambda v: v * tb), alpha.point(lambda v: v * ta)))
            if item["rotation"]:
                tile = tile.rotate(degrees(item["rotation"]), resample=Image.BILINEAR, expand=False)
        else:
            return
        layer = self.overlay()
        layer.paste(tile, (x0, y0))
        self.composite(layer)

    def text(self, item, rect, center=False):
        if not item["text"]:
            return
        font, size, rgb, outline = self.layout.font(item["font"])
        color = item["textColor"] or list(rgb) + [1]
        base = tuple(round(c * 255) for c in color[:3])
        lines = self.layout.lines(item, item["width"])
        l, b, r, t = rect
        layer = self.overlay()
        draw = ImageDraw.Draw(layer)
        spacing = item.get("spacing") or 0
        y = SCREEN_H - t if not center else SCREEN_H - (b + t) / 2 - (len(lines) * size) / 2
        raw_lines = (item["text"] or "").split("\n") if item["width"] is None else None
        for index, line in enumerate(lines):
            segments = []
            source = raw_lines[index] if raw_lines else line
            current, position = base, 0
            for match in re.finditer(r"\|c([0-9a-fA-F]{8})|\|r", source):
                segments.append((source[position:match.start()], current))
                current = tuple(int(match.group(1)[k:k + 2], 16) for k in (2, 4, 6)) if match.group(1) else base
                position = match.end()
            segments.append((source[position:], current))
            total = sum(font.getlength(s) for s, _ in segments)
            justify = item["justify"] or ("CENTER" if center else "LEFT")
            x = l if justify == "LEFT" else r - total if justify == "RIGHT" else (l + r) / 2 - total / 2
            for segment, rgb8 in segments:
                stroke = 2 if outline else 0
                draw.text((x + 1, y + 1), segment, font=font, fill=(0, 0, 0, 220), stroke_width=stroke,
                          stroke_fill=(0, 0, 0, 255))
                draw.text((x, y), segment, font=font, fill=rgb8 + (255,))
                x += font.getlength(segment)
            y += size + spacing
        self.composite(layer)

    def draw(self):
        objects = self.layout.objects
        work = []
        for index in range(1, len(objects)):
            item = objects[index]
            if not item["visible"]:
                continue
            rect = self.layout.rect(index)
            if item["kind"] == "frame":
                if item["backdrop"]:
                    work.append(((item["level"], -1, 0, index), self.backdrop, item, rect))
                if item["frameKind"] == "CheckButton" or item["frameKind"] == "Button" and item["template"]:
                    work.append(((item["level"], 1.5, 0, index), self.button, item, rect))
                if item["template"] == "DialogHeaderTemplate" and item["headerText"]:
                    work.append(((item["level"], 2, 0, index), self.header, item, rect))
            else:
                parent = objects[item["parent"]]
                key = (parent["level"], LAYERS.get(item["layer"], 2), item["sublevel"] or 0, index)
                work.append((key, self.texture if item["kind"] == "texture" else self.text, item, rect))
        for _, paint, item, rect in sorted(work, key=lambda entry: entry[0]):
            paint(item, rect)
        return self.image


CONTROLS = ("Button", "CheckButton", "EditBox")


def plain(text):
    return re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", text or "").strip()


def lint(layout, name, skip=()):
    """Overlaps in each dialog box (a DialogBox backdrop, not the window
    itself, index `skip`): a control on a control, a text on a control it
    does not belong to, a text on a text; a text under a card drawn over it
    (a child frame's opaque backdrop: the client draws a frame's children
    above its own text); and a control outside its dialog. Returns one line
    per fault."""
    objects = layout.objects

    def ancestors(index):
        out, walk = [], objects[index]["parent"]
        while walk:
            out.append(walk)
            walk = objects[walk]["parent"]
        return out

    def dialog(index):
        for walk in ancestors(index):
            item = objects[walk]
            if item["kind"] == "frame" and item["backdrop"] and "DialogBox" in item["backdrop"].split("|")[0] \
                    and walk not in skip:
                return walk
        return None

    def label(index):
        item = objects[index]
        text = plain(item["text"])
        return f"{item['frameKind'] or item['kind']} '{text[:40]}'" if text else f"{item['frameKind'] or item['kind']} #{index}"

    groups, cards = {}, {}
    faults = []
    for index in range(1, len(objects)):
        item = objects[index]
        if not item["visible"]:
            continue
        if item["kind"] == "font" and plain(item["text"]) and item["width"] and \
                any(line.endswith("...") and not plain(item["text"]).endswith("...")
                    for line in layout.lines(item, item["width"])):
            faults.append(f"{name}: {label(index)} is cut short")
        control = item["kind"] == "frame" and item["frameKind"] in CONTROLS
        text = item["kind"] == "font" and plain(item["text"]) != ""
        card = item["kind"] == "frame" and item["backdrop"] and "DialogBox" not in item["backdrop"].split("|")[0] \
            and (item["backdropColor"] or [0, 0, 0, 1])[3] >= 0.5
        if card and dialog(index) is not None:
            cards.setdefault(dialog(index), []).append(index)
        if not (control or text):
            continue
        box = dialog(index)
        if box is not None:
            groups.setdefault(box, []).append((index, control, layout.rect(index)))
    for box, members in groups.items():
        for index, control, (l, b, r, t) in members:
            if control:
                continue
            level = objects[objects[index]["parent"]]["level"]
            for card in cards.get(box, ()):
                if objects[card]["level"] <= level or card in ancestors(index):
                    continue
                cl, cb, cr, ct = layout.rect(card)
                if min(r, cr) - max(l, cl) > 1 and min(t, ct) - max(b, cb) > 1:
                    faults.append(f"{name}: {label(index)} is hidden under {label(card)}")
                    break
        bl, bb, br, bt = layout.rect(box)
        for index, control, (l, b, r, t) in members:
            if control and (l < bl + 4 or r > br - 4 or b < bb + 4 or t > bt - 4):
                faults.append(f"{name}: {label(index)} leaves its dialog")
        for i, (a, control_a, ra) in enumerate(members):
            for z, control_b, rb in members[i + 1:]:
                if not (control_a or control_b) or True:
                    w = min(ra[2], rb[2]) - max(ra[0], rb[0])
                    h = min(ra[3], rb[3]) - max(ra[1], rb[1])
                    if w <= 1 or h <= 1:
                        continue
                    if a in ancestors(z) or z in ancestors(a):
                        continue                       # a label on its own button or row
                    faults.append(f"{name}: {label(a)} overlaps {label(z)} ({w:.0f} x {h:.0f})")
    return faults


FAULTS = []


def capture(lua, name, out_dir, check=False):
    layout = Layout(snapshot(lua))
    if check:
        FAULTS.extend(lint(layout, name, {int(lua.eval("mock.namespace.UI.window.index"))}))
    image = Painter(layout).draw().convert("RGB")
    if out_dir:
        image.save(out_dir / f"{name}.png")
    return image


def check_all(lua):
    """Every menu screen with each track and kart chosen, and the board for
    each track: the faults lint finds."""
    run = lua.execute
    skip = {int(lua.eval("mock.namespace.UI.window.index"))}

    def look(name):
        FAULTS.extend(lint(Layout(snapshot(lua)), name, skip))
    run("mock.namespace.Menu.Show('home')")
    look("home")
    ids = lua.eval("""(function()
        local out, Courses = {}, mock.namespace.Courses
        for _, course in ipairs(Courses.LIST) do if not course.soon then out[#out + 1] = course.id end end
        return out end)()""")
    for i in range(1, len(ids) + 1):
        run(f"mock.namespace.UI.SelectTrack('{ids[i]}'); mock.namespace.Menu.Show('tracks')")
        look(f"tracks/{ids[i]}")
    run("mock.namespace.UI.SelectTrack('mirage_raceway')")
    karts = lua.eval("mock.namespace.Presentation.KART_ORDER")
    for screen in ("karts", "garage"):
        run(f"mock.namespace.Menu.Show('{screen}'); mock.namespace.Menu.view.stage.scripts = nil")
        for i in range(1, len(karts) + 1):
            run(f"mock.namespace.Menu.ChooseKart('{karts[i]}')")
            look(f"{screen}/{karts[i]}")
    run("mock.namespace.Menu.ChooseKart('goblin_mortar_trike')")
    for screen in ("multiplayer", "help", "credits", "settings"):
        run(f"mock.namespace.Menu.Show('{screen}')")
        look(screen)
    run("mock.namespace.Menu.Show('highscores')")
    tracks = int(lua.eval("#mock.namespace.Menu.TRACKS"))
    for i in range(1, tracks + 1):
        run(f"local M = mock.namespace.Menu; M.boardTrackId = M.TRACKS[{i}].id; "
            "M.view.boardList.cup, M.view.boardList.page = nil, nil; M.OnScoresChanged()")
        look(f"highscores/{lua.eval(f'mock.namespace.Menu.TRACKS[{i}].id')}")
    run("mock.namespace.Menu.Show('home')")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", help="the review sheet (default docs/art/ui/front-end-review.png; "
                        "with --check none unless given)")
    parser.add_argument("--screens", help="also write each full-size screen into this folder")
    parser.add_argument("--race-out", help="the race screens' sheet (default docs/art/ui/race-screens-review.png; "
                        "with --check none unless given)")
    parser.add_argument("--client-fonts", help="a folder with the client's frizqt__.ttf and morpheus.ttf")
    parser.add_argument("--check", action="store_true",
                        help="report overlapping or escaping text and controls on every screen; exit 1 on any")
    args = parser.parse_args()
    if not args.check:
        args.out = args.out or str(ROOT / "docs" / "art" / "ui" / "front-end-review.png")
        args.race_out = args.race_out or str(ROOT / "docs" / "art" / "ui" / "race-screens-review.png")
    if args.client_fonts:
        for face, file in CLIENT_FACES.items():
            path = Path(args.client_fonts) / file
            if not path.is_file():
                raise SystemExit(f"--client-fonts: {path} not found")
            FACES[face] = str(path)
    os.chdir(ROOT)
    lupa = importlib.import_module("lupa.lua51")
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.globals().mock.load(lua.table(*MODULES), lua.table(*FONTS.keys()))
    out_dir = Path(args.screens) if args.screens else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
    shots = []
    run = lua.execute
    run("mock.namespace.UI.Toggle(); mock.namespace.UI.SelectTrack('mirage_raceway'); mock.namespace.Menu.Show('home')")
    if args.check:
        check_all(lua)
    check = args.check
    def capture(lua, name, out_dir, check=check, _capture=globals()["capture"]):
        return _capture(lua, name, out_dir, check)
    for screen in ("home", "tracks", "karts", "multiplayer", "help", "credits", "settings", "highscores"):
        run(f"mock.namespace.Menu.Show('{screen}')")
        if screen == "karts":
            run("mock.namespace.Menu.view.stage.scripts = nil")
        shots.append((screen, capture(lua, screen, out_dir)))
    run("mock.namespace.Menu.Show('garage'); mock.namespace.Menu.ChooseKart('steam_tank')")
    shots.append(("garage", capture(lua, "garage", out_dir)))
    run("mock.namespace.Menu.ChooseKart('goblin_mortar_trike'); mock.namespace.Menu.Show(nil)")
    run("""local UI = mock.namespace.UI
        UI.Start(); mock.step(180); mock.key('OnKeyDown', 'W'); mock.step(80)
        mock.key('OnKeyDown', 'A'); mock.key('OnKeyDown', 'SPACE'); mock.step(40)""")
    shots.append(("race", capture(lua, "race", out_dir)))
    run("mock.key('OnKeyUp', 'SPACE'); mock.key('OnKeyUp', 'A'); mock.step(6)")
    shots.append(("boost", capture(lua, "boost", out_dir)))
    run("mock.namespace.UI.Stop('preview'); mock.namespace.Menu.Show(nil); mock.namespace.UI.DismissSummary()")
    run("mock.namespace.UI.SelectTrack('mirage_raceway'); mock.finish({1874, 1818, 1826})")
    shots.append(("results", capture(lua, "results", out_dir)))
    # The results' celebrations: the same run's best saved at #2, then #7, on
    # a shared board of fourteen (a stand-in board; the first finish saves
    # nothing in this mock).
    run("""local ns = mock.namespace
        local UI, Menu = ns.UI, ns.Menu
        mock.board = function(rank)
            local rows = {}
            for i = 1, 14 do rows[i] = {playerName = "Racer " .. i, totalTicks = 5300 + i * 40, finishedAt = 1000 + i} end
            rows[rank] = {playerName = "Carl Bakke", totalTicks = UI.race.totalTicks, finishedAt = 9999}
            ns.SoloRecords.GetView = function() return {scope = "community", rows = rows} end
            UI.scoreResult = {saved = true, totalTicks = UI.race.totalTicks, message = (rank <= 3 and "Top 3" or "Top 10")
                .. " in known shared scores! #" .. rank .. " | Personal best saved: 1:31.92"}
            UI.summary:Hide(); Menu.fanfareRace = nil; UI.summary:Show(); Menu.AnimateResults(0.6)
        end
        mock.board(2)""")
    shots.append(("results: top 3", capture(lua, "results-top3", out_dir)))
    run("mock.board(7); mock.namespace.Menu.AnimateResults(2.6)")
    shots.append(("results: top 10", capture(lua, "results-top10", out_dir)))
    run("mock.namespace.UI.DismissSummary()")
    shots.append(("track view", capture(lua, "track-view", out_dir)))
    # A two-player race as the HUD shows it (a stand-in live view: the friend's
    # kart just ahead, their name over it, the place in the corner), then its
    # results once both have finished.
    run("""local ns = mock.namespace
        local UI, Menu = ns.UI, ns.Menu
        UI.SelectTrack('mirage_raceway'); Menu.Show(nil); UI.Start(); mock.step(180)
        mock.key('OnKeyDown', 'W'); mock.step(70)
        local s = UI.state
        local remote = {x = s.x + 70 * math.cos(s.heading) - 24 * math.sin(s.heading),
            y = s.y + 70 * math.sin(s.heading) + 24 * math.cos(s.heading), heading = s.heading, speed = 150,
            tick = 250, driftTier = 0, boosting = false, completedLaps = 0, passed = 0, status = "running",
            receivedAtMS = 4100, sampleMS = 4100, sampleAgeMS = 0}
        local previous = {}
        for k, v in pairs(remote) do previous[k] = v end
        previous.x, previous.y = remote.x - 20 * math.cos(s.heading), remote.y - 20 * math.sin(s.heading)
        previous.sampleMS, previous.tick = 3600, 220
        UI.multiplayer = true
        UI.liveView = {phase = "running", peer = "Amber Stone", peerKartId = "steam_tank", remote = remote,
            remotePrevious = previous, remoteSequence = 9, elapsedMS = 4100, remoteAgeMS = 0, remoteStale = false}
        mock.step(1)""")
    shots.append(("two-player race", capture(lua, "race-two-player", out_dir)))
    run("""local ns = mock.namespace
        local UI, Menu = ns.UI, ns.Menu
        mock.key('OnKeyUp', 'W')
        UI.active = false
        UI.race = {status = "finished", targetLaps = 3, totalTicks = 5512, laps = {completedLaps = 3,
            lastLapTicks = 1830, bestLapTicks = 1818, checkpoints = {passed = 0}}}
        UI.laps = UI.race.laps
        Menu.view.lapTimes = {1864, 1818, 1830}
        local remote = UI.liveView.remote
        remote.status, remote.tick, remote.completedLaps, remote.passed = "finished", 5611, 3, 0
        UI.liveView.phase, UI.liveView.reason = "closed", "completed_unverified"
        UI.summaryTitle:SetText("LOCAL FINISH — UNVERIFIED")
        UI.summaryHint:SetText("Experimental race | No agreed winner or standings")
        UI.summary:Hide(); Menu.fanfareRace = nil; UI.summary:Show(); Menu.AnimateResults(0.6)""")
    shots.append(("two-player results", capture(lua, "results-two-player", out_dir)))
    run("mock.namespace.UI.summary:Hide(); mock.namespace.UI.multiplayer = false; mock.namespace.UI.liveView = nil")
    # The Capital Cities Cup: the track list with Stormwind chosen, then a
    # drive up the Valley of Heroes on its follow camera.
    run("mock.namespace.UI.SelectTrack('stormwind_city'); mock.namespace.Menu.Show('tracks')")
    shots.append(("tracks: Stormwind", capture(lua, "tracks-stormwind", out_dir)))
    run("""local UI = mock.namespace.UI
        mock.namespace.Menu.Show(nil); UI.Start(); mock.step(180); mock.key('OnKeyDown', 'W'); mock.step(150)""")
    shots.append(("Stormwind race", capture(lua, "race-stormwind", out_dir)))
    run("mock.key('OnKeyUp', 'W'); mock.namespace.UI.Stop('preview'); mock.namespace.Menu.Show(nil)")
    scale, columns = 0.5, 3
    w, h = round(SCREEN_W * scale), round(SCREEN_H * scale)
    rows = (len(shots) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * w + (columns + 1) * 8, rows * (h + 22) + 8), (24, 26, 30))
    draw = ImageDraw.Draw(sheet)
    label = ImageFont.truetype(FACES["friz"], 14)
    for i, (name, image) in enumerate(shots):
        x, y = 8 + (i % columns) * (w + 8), 8 + (i // columns) * (h + 22)
        draw.text((x, y), name, font=label, fill=(230, 230, 230))
        sheet.paste(image.resize((w, h), Image.LANCZOS), (x, y + 18))
    if args.out:
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        sheet.save(args.out, optimize=True)
        print(f"wrote {args.out} ({len(shots)} screens)")
    # The race screens and celebrations, larger: a sheet of their own.
    chosen = [(name, image) for name, image in shots
              if name in ("results: top 3", "results: top 10", "two-player race", "two-player results")]
    scale = 0.75
    w, h = round(SCREEN_W * scale), round(SCREEN_H * scale)
    race = Image.new("RGB", (2 * w + 24, 2 * (h + 26) + 8), (24, 26, 30))
    draw = ImageDraw.Draw(race)
    label = ImageFont.truetype(FACES["friz"], 18)
    for i, (name, image) in enumerate(chosen):
        x, y = 8 + (i % 2) * (w + 8), 8 + (i // 2) * (h + 26)
        draw.text((x, y), name, font=label, fill=(230, 230, 230))
        race.paste(image.resize((w, h), Image.LANCZOS), (x, y + 22))
    if args.race_out:
        out = Path(args.race_out)
        out.parent.mkdir(parents=True, exist_ok=True)
        race.save(out, optimize=True)
        print(f"wrote {out}")
    if args.check:
        faults = sorted(set(FAULTS))
        for fault in faults:
            print("LAYOUT:", fault)
        print(f"CHECK {'FAIL' if faults else 'PASS'}: {len(faults)} layout faults")
        return 1 if faults else 0


if __name__ == "__main__":
    sys.exit(main())
