def create_mifs():
    from scipy.misc import imread
    import numpy as np
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('-f', required=True, type=str)
    args = parser.parse_args()
    filename = args.f

    rgb = imread(filename, False, 'RGB')
    pixel_rgb_list = []

    for r in range(rgb.shape[0]):
        for c in range(rgb.shape[1]):
            bbits = rgb.item((r,c,0))
            gbits = rgb.item((r,c,1))
            rbits = rgb.item((r,c,2))
            pixel_rgb_list.append('%2.2x%2.2x%2.2x' %(rbits,gbits,bbits))

    color_palette = []

    for i in range(len(pixel_rgb_list)):
        if pixel_rgb_list[i] not in color_palette:
            color_palette.append(pixel_rgb_list[i])


    pixel_color_locs = [0 for i in range(len(pixel_rgb_list))]

    for i in range(len(pixel_rgb_list)):
        pixel_color_locs[i] = '%2.2x' %(color_palette.index(pixel_rgb_list[i]))

    index_depth = 256
    index_width = 24

    data_depth = len(pixel_color_locs)
    data_width = 8

    with open('flappy_index.mif', 'w') as f:
        f.write('WIDTH = %d;\n' % (index_width))
        f.write('DEPTH = %d;\n' % (index_depth))
        f.write('ADDRESS_RADIX = HEX;\n')
        f.write('DATA_RADIX = HEX;\n')
        f.write('CONTENT BEGIN\n')

        for i in range(len(color_palette)):
            f.write('%x:%s;\n' %(i, color_palette[i]))

        for i in range(len(color_palette), 256):
            f.write('%x:000000;\n' %(i))

        f.write('END;')

    with open('flappy_data.mif', 'w') as f:
        f.write('WIDTH = %d;\n' % (data_width))
        f.write('DEPTH = %d;\n' % (data_depth))
        f.write('ADDRESS_RADIX = HEX;\n')
        f.write('DATA_RADIX = HEX;\n')
        f.write('CONTENT BEGIN\n')

        for i in range(len(pixel_color_locs)):
            f.write('%x:%s;\n' % (i, pixel_color_locs[i]))

        f.write('END;')

if __name__ == '__main__':
    create_mifs()