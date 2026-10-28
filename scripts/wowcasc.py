"""Read-only World of Warcraft CASC reader: extract files by FileDataID.

python wowcasc.py ROOT extract OUTDIR FDID[=NAME] ... [--cdn] [--product NAME]   # write each file (default name: its FileDataID)
python wowcasc.py ROOT info [--product NAME]

ROOT is the World of Warcraft install folder (holding .build.info and Data/).
Nothing there is written. The build is the first active product line of
.build.info, or the active line named by --product (an install can hold
several: wow_classic_era, wow_classic_beta, ...); files are found through its root manifest (MFST: FileDataID to
content key), the encoding table (content key to encoding key) and the local
indices (encoding key to a data archive), all read lazily: the bucket of an
encoding key is computed and its index searched, so a lookup reads a few
pages, not the whole store. Encrypted (BLTE "E") chunks are not supported.

The client streams many files on demand, so a file may not be stored
locally yet. With --cdn such a file is fetched from Blizzard's CDN, the way
the client fetches it: the install keeps every CDN archive's index
(Data/indices/<archive>.index), which gives the file's archive, offset and
size, and one HTTP range request for those bytes is decoded as stored.
The hosts and path are the build's own (.build.info's CDN Hosts and CDN Path).

Standard library only; BLTE decoding is wc3casc's.
"""
import os
import struct
import sys
import urllib.request

from wc3casc import blte


class WowCasc:
    def __init__(self, root, product=None):
        self.root = root
        self.data = os.path.join(root, "Data", "data")
        info = open(os.path.join(root, ".build.info"), encoding="utf-8").read().splitlines()
        names = [h.split("!")[0] for h in info[0].split("|")]
        rows = [dict(zip(names, line.split("|"))) for line in info[1:] if line.strip()]
        row = next(r for r in rows if r.get("Active") == "1" and product in (None, r.get("Product")))
        self.product, self.version = row.get("Product"), row.get("Version")
        self.cdn_hosts, self.cdn_path = row.get("CDN Hosts", "").split(), row.get("CDN Path", "")
        self.config = self._config(row["Build Key"])
        self.cdn_config = self._config(row["CDN Key"]) if row.get("CDN Key") else {}
        self._buckets = {}
        for name in os.listdir(self.data):
            if len(name) == 14 and name.endswith(".idx"):
                bucket, version = int(name[:2], 16), int(name[2:10], 16)
                if bucket not in self._buckets or version > self._buckets[bucket][0]:
                    self._buckets[bucket] = (version, name)
        self._index_cache = {}
        self._encoding = None

    def _config(self, key):
        out = {}
        for line in open(os.path.join(self.root, "Data", "config", key[:2], key[2:4], key), encoding="utf-8"):
            if " = " in line:
                name, value = line.strip().split(" = ", 1)
                out[name] = value.split()
        return out

    # Local indices: bucket = folded XOR of the key's first nine bytes; the
    # bucket's entries are sorted by key, so a binary search finds one.
    def _index(self, bucket):
        if bucket not in self._index_cache:
            raw = open(os.path.join(self.data, self._buckets[bucket][1]), "rb").read()
            header_size = struct.unpack_from("<I", raw, 0)[0]
            _version, _bucket, _extra, size_len, offs_len, key_len, offs_bits = struct.unpack_from("<HBBBBBB", raw, 8)
            pos = (8 + header_size + 15) & ~15
            entries_size = struct.unpack_from("<I", raw, pos)[0]
            pos += 8
            step = key_len + offs_len + size_len
            self._index_cache[bucket] = (raw, pos, entries_size // step, step, key_len, offs_len, offs_bits)
        return self._index_cache[bucket]

    def locate(self, ekey):
        key = bytes(ekey[:9])
        x = 0
        for b in key:
            x ^= b
        bucket = (x & 0xF) ^ (x >> 4)
        raw, base, count, step, key_len, offs_len, offs_bits = self._index(bucket)
        lo, hi = 0, count - 1
        while lo <= hi:
            mid = (lo + hi) // 2
            p = base + mid * step
            k = raw[p:p + key_len]
            if k == key:
                loc = int.from_bytes(raw[p + key_len:p + key_len + offs_len], "big")
                size = int.from_bytes(raw[p + key_len + offs_len:p + step], "little")
                return loc >> offs_bits, loc & ((1 << offs_bits) - 1), size
            if k < key:
                lo = mid + 1
            else:
                hi = mid - 1
        raise KeyError(ekey.hex())

    def read_ekey(self, ekey):
        archive, offset, size = self.locate(ekey)
        with open(os.path.join(self.data, "data.%03d" % archive), "rb") as f:
            f.seek(offset)
            blob = f.read(size)
        return blte(blob[0x1E:])

    # Encoding: content key -> encoding key, by its sorted page table.
    def _load_encoding(self):
        raw = self.read_ekey(bytes.fromhex(self.config["encoding"][1]))
        assert raw[:2] == b"EN", "not an encoding table"
        ck, ek = raw[3], raw[4]
        page_kb, _espec_kb = struct.unpack_from(">HH", raw, 5)
        pages, _espec_pages = struct.unpack_from(">II", raw, 9)
        espec_size = struct.unpack_from(">I", raw, 18)[0]
        table = 22 + espec_size
        first = [raw[table + i * (ck + 16):table + i * (ck + 16) + ck] for i in range(pages)]
        start = table + pages * (ck + 16)
        self._encoding = (raw, ck, ek, page_kb * 1024, first, start)

    def ekey_of(self, ckey):
        if self._encoding is None:
            self._load_encoding()
        raw, ck, ek, page_size, first, start = self._encoding
        lo, hi = 0, len(first) - 1
        while lo < hi:                                # the last page whose first key <= ckey
            mid = (lo + hi + 1) // 2
            if first[mid] <= ckey:
                lo = mid
            else:
                hi = mid - 1
        p, end = start + lo * page_size, start + (lo + 1) * page_size
        while p + 6 + ck <= end:
            count = raw[p]
            if count == 0:
                break
            key = raw[p + 6:p + 6 + ck]
            if key == ckey:
                return raw[p + 6 + ck:p + 6 + ck + ek]
            p += 6 + ck + ek * count
        raise KeyError(ckey.hex())

    # Root manifest (MFST): FileDataID -> content key, for the wanted IDs.
    def ckeys(self, wanted, locale=0x2):
        """{fdid: ckey} for the FileDataIDs in `wanted` (enUS, or all-locale entries)."""
        raw = self.read_ekey(self.ekey_of(bytes.fromhex(self.config["root"][0])))
        wanted, found = set(wanted), {}
        pos, version = 0, 1
        if raw[:4] == b"TSFM":
            header_size, version = struct.unpack_from("<II", raw, 4)
            if header_size not in (0x18, 0x14):          # the oldest MFST: magic, total, named counts
                header_size, version = 12, 1
            pos = header_size
        while pos < len(raw):
            if version >= 2:
                count, locales, flags1, flags2 = struct.unpack_from("<IIII", raw, pos)
                flags = flags1 | flags2 | (raw[pos + 16] << 17)
                pos += 17
            else:
                count, flags, locales = struct.unpack_from("<III", raw, pos)
                pos += 12
            deltas = struct.unpack_from("<%di" % count, raw, pos)
            pos += 4 * count
            keys = pos
            pos += 16 * count
            if not flags & 0x10000000:                   # name hashes follow unless NoNameHash
                pos += 8 * count
            if not (locales & locale or locales == 0xFFFFFFFF or locales == 0):
                continue
            fdid = -1
            for i, delta in enumerate(deltas):
                fdid += 1 + delta
                if fdid in wanted and fdid not in found:
                    found[fdid] = raw[keys + 16 * i:keys + 16 * i + 16]
        return found

    # CDN archives: each archive's index is blocks of sorted (key, size,
    # offset) entries, then a table of every block's last key, then a footer.
    def cdn_locate(self, ekeys):
        """{ekey: (archive, offset, size)} for those of `ekeys` in the CDN archives."""
        wanted, found = sorted(set(ekeys)), {}
        for archive in self.cdn_config.get("archives", []):
            path = os.path.join(self.root, "Data", "indices", archive + ".index")
            if not os.path.isfile(path):
                continue
            with open(path, "rb") as f:
                f.seek(0, 2)
                length = f.tell()
                f.seek(length - 28)
                footer = f.read(28)
                block_kb, offs_len, size_len, key_len, sum_len = footer[11], footer[12], footer[13], footer[14], footer[15]
                assert footer[8] == 1 and sum_len == 8, "unexpected archive index footer"
                block = block_kb * 1024
                blocks = (length - 28) // (block + key_len + sum_len)
                f.seek(blocks * block)
                last = f.read(blocks * key_len)
                step = key_len + size_len + offs_len
                for ekey in wanted:
                    if ekey in found:
                        continue
                    lo, hi = 0, blocks - 1                    # the first block whose last key >= ekey
                    while lo < hi:
                        mid = (lo + hi) // 2
                        if last[mid * key_len:(mid + 1) * key_len] < ekey:
                            lo = mid + 1
                        else:
                            hi = mid
                    if blocks == 0 or last[lo * key_len:(lo + 1) * key_len] < ekey:
                        continue
                    f.seek(lo * block)
                    entries = f.read(block)
                    for p in range(0, block - step + 1, step):
                        if entries[p:p + key_len] == ekey:
                            size = int.from_bytes(entries[p + key_len:p + key_len + size_len], "big")
                            offset = int.from_bytes(entries[p + key_len + size_len:p + step], "big")
                            found[ekey] = (archive, offset, size)
                            break
        return found

    def cdn_read(self, archive, offset=None, size=None):
        """Bytes of a CDN data file (or a range of it), from the build's first host that answers."""
        failures = []
        for host in self.cdn_hosts:
            url = "http://%s/%s/data/%s/%s/%s" % (host, self.cdn_path, archive[:2], archive[2:4], archive)
            request = urllib.request.Request(url)
            if offset is not None:
                request.add_header("Range", "bytes=%d-%d" % (offset, offset + size - 1))
            try:
                with urllib.request.urlopen(request, timeout=60) as response:
                    data = response.read()
                if size is None or len(data) == size:
                    return data
                failures.append("%s: %d bytes, not %d" % (host, len(data), size))
            except OSError as error:
                failures.append("%s: %s" % (host, error))
        raise OSError("CDN fetch of %s failed (%s)" % (archive, "; ".join(failures)))

    def read_fdids(self, wanted, cdn=False):
        """{fdid: bytes} for the wanted files. Without `cdn`, files the client
        has not stored locally are left out; with it, they are fetched."""
        out, remote = {}, {}
        for fdid, ckey in self.ckeys(wanted).items():
            ekey = self.ekey_of(ckey)
            try:
                out[fdid] = self.read_ekey(ekey)
            except KeyError:
                remote[fdid] = ekey
        if cdn and remote:
            places = self.cdn_locate(remote.values())
            for fdid, ekey in remote.items():
                if ekey in places:
                    out[fdid] = blte(self.cdn_read(*places[ekey]))
                else:                                        # an unarchived file is stored under its own key
                    out[fdid] = blte(self.cdn_read(ekey.hex()))
        return out


def main():
    args = [a for a in sys.argv[1:] if a != "--cdn"]
    cdn = len(args) != len(sys.argv) - 1
    product = None
    if "--product" in args:
        at = args.index("--product")
        product = args[at + 1]
        del args[at:at + 2]
    root, command = args[0], args[1]
    casc = WowCasc(root, product)
    if command == "info":
        print(casc.product, casc.version, casc.config.get("build-name"))
        return
    if command == "extract":
        out = args[2]
        names = {}
        for arg in args[3:]:
            fdid, _, name = arg.partition("=")
            names[int(fdid)] = name or fdid
        files = casc.read_fdids(names, cdn)
        for fdid, name in names.items():
            if fdid not in files:
                print("MISSING", fdid, name, "(not stored locally; add --cdn to fetch it)" if not cdn else "")
                continue
            target = os.path.join(out, *name.split("/"))
            os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
            with open(target, "wb") as f:
                f.write(files[fdid])
            print(len(files[fdid]), fdid, name)


if __name__ == "__main__":
    main()
