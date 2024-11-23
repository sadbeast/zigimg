const PixelFormat = @import("../../src/pixel_format.zig").PixelFormat;
const icn = @import("../../src/formats/icn.zig");
const color = @import("../../src/color.zig");
const std = @import("std");
const testing = std.testing;
const Image = @import("../../src/Image.zig");
const helpers = @import("../helpers.zig");

const working_icn_file = helpers.fixtures_path ++ "icn/test02x02.icn";

test "Read icn file" {
    const file = try helpers.testOpenFile(working_icn_file);
    defer file.close();

    var stream_source = std.io.StreamSource{ .file = file };

    var icn_file = icn.ICN.init(16, 16);

    const pixels = try icn_file.read(helpers.zigimg_test_allocator, &stream_source);
    defer pixels.deinit(helpers.zigimg_test_allocator);

    try helpers.expectEq(icn_file.width(), 16);
    try helpers.expectEq(icn_file.height(), 16);
    try helpers.expectEq(try icn_file.pixelFormat(), .indexed1);

    try testing.expect(pixels == .indexed1);
    try helpers.expectEq(pixels.indexed1.indices[0], 1);
    try helpers.expectEq(pixels.indexed1.indices[1], 0);
    try helpers.expectEq(pixels.indexed1.indices[2], 1);
    try helpers.expectEq(pixels.indexed1.indices[3], 0);
    try helpers.expectEq(pixels.indexed1.indices[16 * 8 + 8], 1);
    try helpers.expectEq(pixels.indexed1.indices[16 * 8 + 9], 0);
}
