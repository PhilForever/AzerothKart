"""Baseline JPEG decoding for Warcraft III BLP1 textures, standard library only.

Warcraft III stores most BLP1 textures as JPEG: a header shared by all mip
levels, followed by each level's scan. The four components are the texture's
blue, green, red and alpha channels, with no color transform and no chroma
subsampling. This module decodes exactly that subset: baseline sequential
Huffman JPEG, 8-bit samples, every component sampled 1x1, no restart
intervals. Anything else is refused with an error rather than guessed.

The inverse DCT is libjpeg's integer "islow" algorithm (jidctint.c,
including its range-limit table), so the samples match libjpeg and
libjpeg-turbo and are identical on every platform: only Python integer
arithmetic is used.
"""
import struct

ZIGZAG = [0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6,
          7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31,
          39, 46, 53, 60, 61, 54, 47, 55, 62, 63]

# jidctint.c fixed-point constants, CONST_BITS = 13.
CONST_BITS, PASS1_BITS = 13, 2
F0298, F0390, F0541, F0765, F0899, F1175 = 2446, 3196, 4433, 6270, 7373, 9633
F1501, F1847, F1961, F2053, F2562, F3072 = 12299, 15137, 16069, 16819, 20995, 25172


def _limit(value):
    """libjpeg's post-IDCT range limit: wrap to [-512, 511] (RANGE_MASK), recenter, clamp."""
    value = ((value + 512) & 1023) - 512 + 128
    return 0 if value < 0 else 255 if value > 255 else value


def idct_islow(coef, quant):
    """One 8x8 block: dequantize natural-order coefficients and return 64 samples."""
    ws = [0] * 64
    shift, rounding = CONST_BITS - PASS1_BITS, 1 << (CONST_BITS - PASS1_BITS - 1)
    for c in range(8):
        if not (coef[8 + c] or coef[16 + c] or coef[24 + c] or coef[32 + c] or coef[40 + c] or coef[48 + c]
                or coef[56 + c]):
            dc = (coef[c] * quant[c]) << PASS1_BITS
            for k in range(8):
                ws[8 * k + c] = dc
            continue
        z2, z3 = coef[16 + c] * quant[16 + c], coef[48 + c] * quant[48 + c]
        z1 = (z2 + z3) * F0541
        tmp2, tmp3 = z1 - z3 * F1847, z1 + z2 * F0765
        z2, z3 = coef[c] * quant[c], coef[32 + c] * quant[32 + c]
        tmp0, tmp1 = (z2 + z3) << CONST_BITS, (z2 - z3) << CONST_BITS
        tmp10, tmp13, tmp11, tmp12 = tmp0 + tmp3, tmp0 - tmp3, tmp1 + tmp2, tmp1 - tmp2
        t0, t1 = coef[56 + c] * quant[56 + c], coef[40 + c] * quant[40 + c]
        t2, t3 = coef[24 + c] * quant[24 + c], coef[8 + c] * quant[8 + c]
        z1, z2, z3, z4 = t0 + t3, t1 + t2, t0 + t2, t1 + t3
        z5 = (z3 + z4) * F1175
        t0, t1, t2, t3 = t0 * F0298, t1 * F2053, t2 * F3072, t3 * F1501
        z1, z2, z3, z4 = -z1 * F0899, -z2 * F2562, -z3 * F1961 + z5, -z4 * F0390 + z5
        t0 += z1 + z3
        t1 += z2 + z4
        t2 += z2 + z3
        t3 += z1 + z4
        ws[c] = (tmp10 + t3 + rounding) >> shift
        ws[56 + c] = (tmp10 - t3 + rounding) >> shift
        ws[8 + c] = (tmp11 + t2 + rounding) >> shift
        ws[48 + c] = (tmp11 - t2 + rounding) >> shift
        ws[16 + c] = (tmp12 + t1 + rounding) >> shift
        ws[40 + c] = (tmp12 - t1 + rounding) >> shift
        ws[24 + c] = (tmp13 + t0 + rounding) >> shift
        ws[32 + c] = (tmp13 - t0 + rounding) >> shift
    out = [0] * 64
    shift, rounding = CONST_BITS + PASS1_BITS + 3, 1 << (CONST_BITS + PASS1_BITS + 2)
    for row in range(0, 64, 8):
        w = ws[row:row + 8]
        z2, z3 = w[2], w[6]
        z1 = (z2 + z3) * F0541
        tmp2, tmp3 = z1 - z3 * F1847, z1 + z2 * F0765
        tmp0, tmp1 = (w[0] + w[4]) << CONST_BITS, (w[0] - w[4]) << CONST_BITS
        tmp10, tmp13, tmp11, tmp12 = tmp0 + tmp3, tmp0 - tmp3, tmp1 + tmp2, tmp1 - tmp2
        t0, t1, t2, t3 = w[7], w[5], w[3], w[1]
        z1, z2, z3, z4 = t0 + t3, t1 + t2, t0 + t2, t1 + t3
        z5 = (z3 + z4) * F1175
        t0, t1, t2, t3 = t0 * F0298, t1 * F2053, t2 * F3072, t3 * F1501
        z1, z2, z3, z4 = -z1 * F0899, -z2 * F2562, -z3 * F1961 + z5, -z4 * F0390 + z5
        t0 += z1 + z3
        t1 += z2 + z4
        t2 += z2 + z3
        t3 += z1 + z4
        out[row] = _limit((tmp10 + t3 + rounding) >> shift)
        out[row + 7] = _limit((tmp10 - t3 + rounding) >> shift)
        out[row + 1] = _limit((tmp11 + t2 + rounding) >> shift)
        out[row + 6] = _limit((tmp11 - t2 + rounding) >> shift)
        out[row + 2] = _limit((tmp12 + t1 + rounding) >> shift)
        out[row + 5] = _limit((tmp12 - t1 + rounding) >> shift)
        out[row + 3] = _limit((tmp13 + t0 + rounding) >> shift)
        out[row + 4] = _limit((tmp13 - t0 + rounding) >> shift)
    return out


def _huffman(counts, symbols):
    """A 16-bit lookup table: next 16 bits -> (symbol, code length)."""
    table = [None] * 65536
    code = k = 0
    for length in range(1, 17):
        for _ in range(counts[length - 1]):
            first = code << (16 - length)
            entry = (symbols[k], length)
            for value in range(first, first + (1 << (16 - length))):
                table[value] = entry
            code += 1
            k += 1
        code <<= 1
    return table


def decode(jpeg):
    """Decode a JPEG stream; returns (width, height, [component sample lists])."""
    assert jpeg[:2] == b"\xff\xd8", "not a JPEG stream"
    quant, huffman, frame, pos = {}, {}, None, 2
    while True:
        assert jpeg[pos] == 0xFF, "malformed JPEG marker"
        marker = jpeg[pos + 1]
        length = struct.unpack_from(">H", jpeg, pos + 2)[0]
        segment = jpeg[pos + 4:pos + 2 + length]
        pos += 2 + length
        if marker == 0xDB:                                   # quantization tables
            i = 0
            while i < len(segment):
                assert segment[i] >> 4 == 0, "16-bit quantization tables are not supported"
                natural = [0] * 64
                for k in range(64):
                    natural[ZIGZAG[k]] = segment[i + 1 + k]
                quant[segment[i] & 15] = natural
                i += 65
        elif marker == 0xC4:                                 # Huffman tables
            i = 0
            while i < len(segment):
                counts = list(segment[i + 1:i + 17])
                n = sum(counts)
                huffman[(segment[i] >> 4, segment[i] & 15)] = _huffman(counts, list(segment[i + 17:i + 17 + n]))
                i += 17 + n
        elif marker in (0xC0, 0xC1):                         # baseline / extended sequential, Huffman
            assert segment[0] == 8, "only 8-bit samples are supported"
            height, width = struct.unpack_from(">HH", segment, 1)
            frame = [(segment[6 + 3 * k], segment[7 + 3 * k], segment[8 + 3 * k]) for k in range(segment[5])]
            assert all(sampling == 0x11 for _, sampling, _ in frame), "only 1x1 sampling is supported"
        elif marker == 0xDD:
            assert struct.unpack_from(">H", segment)[0] == 0, "restart intervals are not supported"
        elif marker == 0xDA:                                 # start of scan
            n = segment[0]
            selectors = {segment[1 + 2 * k]: segment[2 + 2 * k] for k in range(n)}
            assert frame and n == len(frame), "the scan must interleave every component"
            assert segment[1 + 2 * n:4 + 2 * n] == bytes((0, 63, 0)), "only baseline scans are supported"
            break
        elif marker in (0xC2, 0xC3) or 0xC5 <= marker <= 0xCF:
            raise AssertionError(f"unsupported JPEG process (marker {marker:02X})")
    data, i = bytearray(), pos
    while i < len(jpeg):                                     # entropy-coded segment, unstuffed
        byte = jpeg[i]
        if byte == 0xFF:
            if jpeg[i + 1] != 0x00:
                break
            i += 1
        data.append(byte)
        i += 1
    bits = "".join(format(byte, "08b") for byte in data) + "1" * 32
    p = 0
    blocks_x, blocks_y = (width + 7) // 8, (height + 7) // 8
    stride = blocks_x * 8
    planes = [[0] * (stride * blocks_y * 8) for _ in frame]
    predictors = [0] * len(frame)
    tables = [(huffman[(0, selectors[cid] >> 4)], huffman[(1, selectors[cid] & 15)], quant[tq])
              for cid, _, tq in frame]
    for by in range(blocks_y):
        for bx in range(blocks_x):
            for ci, (dc_table, ac_table, q) in enumerate(tables):
                coef = [0] * 64
                size, length = dc_table[int(bits[p:p + 16], 2)]
                p += length
                diff = 0
                if size:
                    diff = int(bits[p:p + size], 2)
                    if diff < 1 << (size - 1):
                        diff -= (1 << size) - 1
                    p += size
                predictors[ci] += diff
                coef[0] = predictors[ci]
                k = 1
                while k < 64:
                    symbol, length = ac_table[int(bits[p:p + 16], 2)]
                    p += length
                    run, size = symbol >> 4, symbol & 15
                    if size == 0:
                        if run != 15:
                            break                            # end of block
                        k += 16
                        continue
                    k += run
                    value = int(bits[p:p + size], 2)
                    if value < 1 << (size - 1):
                        value -= (1 << size) - 1
                    p += size
                    coef[ZIGZAG[k]] = value
                    k += 1
                samples = idct_islow(coef, q)
                plane, base = planes[ci], by * 8 * stride + bx * 8
                for r in range(8):
                    plane[base + r * stride:base + r * stride + 8] = samples[r * 8:r * 8 + 8]
    if stride != width or blocks_y * 8 != height:
        planes = [[plane[y * stride + x] for y in range(height) for x in range(width)] for plane in planes]
    return width, height, planes


def blp1_jpeg_texels(data):
    """Mip 0 of a JPEG-compressed BLP1 as straight (r, g, b, a) floats in [0, 1], rows top to bottom."""
    assert data[:4] == b"BLP1" and struct.unpack_from("<I", data, 4)[0] == 0, "not a JPEG BLP1"
    width, height = struct.unpack_from("<2I", data, 12)
    offset, size = struct.unpack_from("<I", data, 28)[0], struct.unpack_from("<I", data, 92)[0]
    header_size = struct.unpack_from("<I", data, 156)[0]
    w, h, (blue, green, red, alpha) = decode(data[160:160 + header_size] + data[offset:offset + size])
    assert (w, h) == (width, height), "JPEG size differs from the BLP header"
    if struct.unpack_from("<I", data, 8)[0] == 0:            # no alpha bits: opaque
        alpha = [255] * (w * h)
    return w, h, [(red[i] / 255.0, green[i] / 255.0, blue[i] / 255.0, alpha[i] / 255.0) for i in range(w * h)]
