from compiler.bytemap import bytecode


def getCode(instr):
    i = instr.replace('\n', '').replace(' ', '') + 'b1'
    l = int(len(i) / 2)
    # print(l, format(24 + l, '04x'), format(l, '04x'))

    r = """
cafe babe 0000 0034
0028

0a00 0700 1209 0013 0014
0a00 1500 1609 0013 0017
0a00 1800 1907 001a

0700 1b01 0006 3c69 6e69 743e

010003282956010004436f6465
01000f4c696e654e756d6265725461626c650100046d61696e010016285b4c6
a6176612f6c616e672f537472696e673b295601000a457863657074696f6e73
07001c01000a536f7572636546696c65010006412e6a6176610c00080009070
01d0c001e001f0700200c002100220c002300240700250c0026002701000141
0100106a6176612f6c616e672f4f626a6563740100136a6176612f696f2f494
f457863657074696f6e0100106a6176612f6c616e672f53797374656d010002
696e0100154c6a6176612f696f2f496e70757453747265616d3b0100136a617
6612f696f2f496e70757453747265616d010004726561640100032829490100
036f75740100154c6a6176612f696f2f5072696e7453747265616d3b0100136
a6176612f696f2f5072696e7453747265616d0100077072696e746c6e010004
284929560020000600070000000000020000000800090001000a0000001d000
10001000000052ab70001b100000001000b000000060001000000010009000c
000d 0002 000a
0000 %s
0002 0002
0000 %s
 %s
00000001000b00000006000100000001000e000000040001000f00010010000
0000 2001 1
""" % (format(24 + l, '04x'), format(l, '04x'), i)
    r = r.replace('\n', '').replace(' ', '')
    return [int(i + j, 16) for i, j in list(zip(r[::2], r[1::2]))]


s = list(open('/tmp/a/A.class', 'br').read())
# s = [int(i + j, 16) for i, j in list(zip(s[::2], s[1::2]))]
# s = [j for i in zip(s[1::2], s[::2]) for j in i]

toAsm = {}
tyByte = {}
for i, b, a in bytecode:
    toAsm[int(b, 16)] = (i, a)
    tyByte[i] = int(b, 16)
#
# l = []
# while s:
#     a = s.pop(0)
#     r = toAsm.get(a, ('!' + str(a), 0))
#     args = []
#     if r[1]:
#         for i in range(r[1]):
#             # args.append(str(hex(0)))
#             args.append(str(hex(s.pop(0))))
#
#     l.append((hex(a), r[0], ('(' + ','.join(args) + ')' if args else '')))
#
# for i in l:
#     print(*i)

"""
0021
0006
0007

0000

0001

001a  # ACC_PRIVATE, ACC_STATIC, ACC_FINAL
0008  # name: a
0009  # type: [I
0000  # attributes_count

0004


0001
000a

00 0b 00 01 00 0c 00 00
00 1d 00 01 00 01 00 00  00 05 2a b7 00 01 b1 00
00 00 01 00 0d 00 00 00  06 00 01 00 00 00 01 00
09 00 0e 00 0f 00 01 00  0c 00 00 00 27 00 02 00
01 00 00 00 0b b2 00 02  05 b8 00 03 b6 00 04

    b1
0000
0001
    000d 0000000a
        0002
            0000 0006
            000a 0007

0009   # mask
0008  # metod name

0010 00 01 00 0c 00 00
00 1a 00 01 00 01 00 00  00 02 1a ac
0000
0001
    000d 00000006
        0001
            0000 000b

0008   # mask
0011   <clinit>
000b   ()V
0001
    000c 00000020
        0001 0000 0000

    0008

    10 0a
    bc 0a
    b3 0005
    b1

0000
0001
    000d 00000006
        0001
            0000 0003

0001
    0012 00000002
        0013


"""


while s:
    l = ''
    for j in range(32):
        i = s.pop(0)
        if not s:
            break
        l += format(i, '02x')

    print(l)
