"""Read-only Warcraft III (Reforged) CASC reader: list and extract named files.

python wc3casc.py ROOT list [REGEX]          # print matching paths (cached listfile)
python wc3casc.py ROOT extract REGEX OUTDIR  # write matching files under OUTDIR
python wc3casc.py ROOT info

ROOT is the install folder holding .build.info and Data/. Nothing there is
written. Supports the local index (v7), BLTE (N/Z chunks) and TVFS roots,
including nested VFS directories, which is what Reforged 1.32+ uses.
"""
import os, re, struct, sys, zlib

class Casc:
    def __init__(self, root):
        self.root = root
        self.data = os.path.join(root, "Data", "data")
        info = open(os.path.join(root, ".build.info"), encoding="utf-8").read().splitlines()
        names = [h.split("!")[0] for h in info[0].split("|")]
        row = dict(zip(names, info[1].split("|")))
        bk = row["Build Key"]
        path = os.path.join(root, "Data", "config", bk[:2], bk[2:4], bk)
        self.config = {}
        for line in open(path, encoding="utf-8"):
            if " = " in line:
                key, value = line.strip().split(" = ", 1)
                self.config[key] = value.split()
        self.index = {}
        self._load_indices()
        self.vfs_ekeys = {}
        for key, value in self.config.items():
            if key.startswith("vfs-") and not key.endswith("-size") and len(value) >= 2:
                self.vfs_ekeys[bytes.fromhex(value[1])[:9]] = key

    def _load_indices(self):
        latest = {}
        for name in os.listdir(self.data):
            m = re.fullmatch(r"([0-9a-f]{2})([0-9a-f]{8})\.idx", name)
            if m:
                bucket, version = m.group(1), int(m.group(2), 16)
                if bucket not in latest or version > latest[bucket][0]:
                    latest[bucket] = (version, name)
        for _, name in latest.values():
            raw = open(os.path.join(self.data, name), "rb").read()
            header_size = struct.unpack_from("<I", raw, 0)[0]
            (version, bucket, extra, size_len, offs_len, key_len, offs_bits) = struct.unpack_from("<HBBBBBB", raw, 8)
            pos = (8 + header_size + 15) & ~15
            entries_size = struct.unpack_from("<I", raw, pos)[0]
            pos += 8
            step = key_len + offs_len + size_len
            mask = (1 << offs_bits) - 1
            for p in range(pos, pos + entries_size - step + 1, step):
                key = raw[p:p + key_len]
                loc = int.from_bytes(raw[p + key_len:p + key_len + offs_len], "big")
                size = int.from_bytes(raw[p + key_len + offs_len:p + step], "little")
                if key not in self.index:
                    self.index[key] = (loc >> offs_bits, loc & mask, size)

    def read_ekey(self, ekey):
        archive, offset, size = self.index[bytes(ekey[:9])]
        with open(os.path.join(self.data, "data.%03d" % archive), "rb") as f:
            f.seek(offset)
            blob = f.read(size)
        return blte(blob[0x1E:])

    # TVFS -------------------------------------------------------------
    def files(self):
        if hasattr(self, "_files"):
            return self._files
        self._files = {}
        root = self.read_ekey(bytes.fromhex(self.config["vfs-root"][1]))
        self._parse_tvfs(root, "")
        return self._files

    def _parse_tvfs(self, raw, prefix):
        assert raw[:4] == b"TVFS", "not a TVFS directory"
        version, header_size, ekey_size, patch_size = raw[4], raw[5], raw[6], raw[7]
        flags, pt_off, pt_size, vfs_off, vfs_size, cft_off, cft_size = struct.unpack_from(">7I", raw, 8)
        def width(n):
            return 4 if n > 0xFFFFFF else 3 if n > 0xFFFF else 2 if n > 0xFF else 1
        cft_w = width(cft_size)
        def walk(pos, end, path):
            while pos < end:
                name, value, has_value = b"", 0, False
                pre = post = False
                if raw[pos] == 0:
                    pre, pos = True, pos + 1
                if pos < end and raw[pos] != 0xFF:
                    n = raw[pos]
                    name, pos = raw[pos + 1:pos + 1 + n], pos + 1 + n
                if pos < end and raw[pos] == 0:
                    post, pos = True, pos + 1
                if pos < end and raw[pos] == 0xFF:
                    value, has_value = struct.unpack_from(">I", raw, pos + 1)[0], True
                    pos += 5
                part = path + ("/" if pre else "") + name.decode("utf-8", "replace") + ("/" if post else "")
                if not has_value:
                    path = part
                    continue
                if value & 0x80000000:
                    sub_end = pos + (value & 0x7FFFFFFF) - 4
                    walk(pos, sub_end, part)
                    pos = sub_end
                else:
                    v = pt_end_vfs = vfs_off + value
                    count = raw[v]
                    spans, q = [], v + 1
                    for _ in range(count):
                        file_off, span_size = struct.unpack_from(">II", raw, q)
                        cft = int.from_bytes(raw[q + 8:q + 8 + cft_w], "big")
                        q += 8 + cft_w
                        c = cft_off + cft
                        spans.append((raw[c:c + ekey_size], span_size))
                    ekey = spans[0][0]
                    if ekey[:9] in self.vfs_ekeys and len(spans) == 1:
                        sub = self.read_ekey(ekey)
                        if sub[:4] == b"TVFS":
                            self._parse_tvfs(sub, prefix + part + ":")
                            path = path_base
                            continue
                    self._files[prefix + part] = spans
                path = path_base
        path_base = ""
        # Each sibling restarts from its parent's path: walk() resets per entry.
        def walk_root(pos, end, base):
            nonlocal path_base
            saved = path_base
            path_base = base
            self._walk(raw, pos, end, base, prefix, cft_off, vfs_off, ekey_size, cft_w)
            path_base = saved
        self._walk(raw, pt_off, pt_off + pt_size, "", prefix, cft_off, vfs_off, ekey_size, cft_w)

    def _walk(self, raw, pos, end, base, prefix, cft_off, vfs_off, ekey_size, cft_w):
        path = base
        while pos < end:
            name, has_value, value = b"", False, 0
            pre = post = False
            if raw[pos] == 0:
                pre, pos = True, pos + 1
            if pos < end and raw[pos] != 0xFF:
                n = raw[pos]
                name, pos = raw[pos + 1:pos + 1 + n], pos + 1 + n
            if pos < end and raw[pos] == 0:
                post, pos = True, pos + 1
            if pos < end and raw[pos] == 0xFF:
                value, has_value = struct.unpack_from(">I", raw, pos + 1)[0], True
                pos += 5
            path = path + ("/" if pre else "") + name.decode("utf-8", "replace") + ("/" if post else "")
            if not has_value:
                # A name with no node value is a whole directory component:
                # the path separator after it is implied.
                if not path.endswith("/"):
                    path += "/"
                continue
            if value & 0x80000000:
                sub_end = pos + (value & 0x7FFFFFFF) - 4
                self._walk(raw, pos, sub_end, path, prefix, cft_off, vfs_off, ekey_size, cft_w)
                pos = sub_end
            else:
                v = vfs_off + value
                count = raw[v]
                spans, q = [], v + 1
                for _ in range(count):
                    file_off, span_size = struct.unpack_from(">II", raw, q)
                    cft = int.from_bytes(raw[q + 8:q + 8 + cft_w], "big")
                    q += 8 + cft_w
                    c = cft_off + cft
                    spans.append((raw[c:c + ekey_size], span_size))
                ekey = spans[0][0]
                nested = False
                if ekey[:9] in self.vfs_ekeys and len(spans) == 1:
                    sub = self.read_ekey(ekey)
                    if sub[:4] == b"TVFS":
                        self._parse_tvfs(sub, prefix + path + ":")
                        nested = True
                if not nested:
                    self._files[prefix + path] = spans
            path = base

    def read_path(self, path):
        spans = self.files()[path]
        return b"".join(self.read_ekey(ekey) for ekey, _ in spans)


def blte(blob):
    assert blob[:4] == b"BLTE", "not BLTE"
    header_size = struct.unpack_from(">I", blob, 4)[0]
    if header_size == 0:
        return chunk(blob[8:])
    count = int.from_bytes(blob[9:12], "big")
    pos, out = 12, []
    sizes = []
    for _ in range(count):
        comp, decomp = struct.unpack_from(">II", blob, pos)
        sizes.append(comp)
        pos += 24
    pos = header_size
    for comp in sizes:
        out.append(chunk(blob[pos:pos + comp]))
        pos += comp
    return b"".join(out)


def chunk(data):
    mode = data[:1]
    if mode == b"N":
        return data[1:]
    if mode == b"Z":
        return zlib.decompress(data[1:])
    if mode == b"F":
        return blte(data[1:])
    raise ValueError("unsupported BLTE chunk mode %r" % mode)


def main():
    root, command = sys.argv[1], sys.argv[2]
    casc = Casc(root)
    if command == "info":
        print("indexed keys:", len(casc.index))
        print("build:", casc.config.get("build-name"))
        files = casc.files()
        print("files:", len(files))
        for p in sorted(files)[:20]:
            print(" ", p)
        return
    pattern = re.compile(sys.argv[3] if len(sys.argv) > 3 else ".", re.I)
    files = casc.files()
    if command == "list":
        for p in sorted(files):
            if pattern.search(p):
                print(p)
    elif command == "models":
        # Matching .mdx files plus every texture their TEXS chunk names
        # (Reforged stores the classic .blp names as .dds files).
        out = sys.argv[4]
        wanted = [p for p in sorted(files) if pattern.search(p) and p.endswith(".mdx")]
        lower = {p.lower(): p for p in files}
        done = set()
        for p in wanted:
            mod = p.rsplit(":", 1)[0] + ":" if ":" in p else ""
            data = casc.read_path(p)
            names = [p]
            i = data.find(b"TEXS")
            if i >= 0:
                size = struct.unpack_from("<I", data, i + 4)[0]
                for k in range(size // 268):
                    name = data[i + 8 + k * 268 + 4:i + 8 + k * 268 + 264].split(b"\0")[0].decode("latin1")
                    if not name:
                        continue
                    stem = name.replace("\\", "/").lower().rsplit(".", 1)[0]
                    for ext in (".dds", ".blp", ".tga", ".tif"):
                        for base in (mod, "war3.w3mod:"):
                            key = base + stem + ext
                            if key in lower:
                                names.append(lower[key])
                                break
                        else:
                            continue
                        break
                    else:
                        print("MISSING texture", name, "for", p)
            for q in names:
                if q in done:
                    continue
                done.add(q)
                target = os.path.join(out, *re.split(r"[:/\\]+", q))
                os.makedirs(os.path.dirname(target), exist_ok=True)
                blob = data if q == p else casc.read_path(q)
                with open(target, "wb") as f:
                    f.write(blob)
                print(len(blob), q)
    elif command == "extract":
        out = sys.argv[4]
        for p in sorted(files):
            if pattern.search(p):
                target = os.path.join(out, *re.split(r"[:/\\]+", p))
                os.makedirs(os.path.dirname(target), exist_ok=True)
                try:
                    data = casc.read_path(p)
                except Exception as error:
                    print("FAIL", p, error)
                    continue
                with open(target, "wb") as f:
                    f.write(data)
                print(len(data), p)

if __name__ == "__main__":
    main()
