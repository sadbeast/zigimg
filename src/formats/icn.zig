// https://wiki.xxiivv.com/site/icn_format.html

const Allocator = std.mem.Allocator;
const buffered_stream_source = @import("../buffered_stream_source.zig");
const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const fs = std.fs;
const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const ImageError = ImageUnmanaged.Error;
const ImageReadError = ImageUnmanaged.ReadError;
const ImageWriteError = ImageUnmanaged.WriteError;
const io = std.io;
const mem = std.mem;
const path = std.fs.path;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const std = @import("std");
const utils = @import("../utils.zig");

pub const ICN = struct {
    const Self = @This();

    icn_width: usize = 0,
    icn_height: usize = 0,

    pub fn init(w: usize, h: usize) Self {
        return .{
            .icn_width = w,
            .icn_height = h,
        };
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() ImageUnmanaged.Format {
        return ImageUnmanaged.Format.icn;
    }

    pub fn formatDetect(_: *ImageUnmanaged.Stream) ImageReadError!bool {
        // TODO: I don't know of a good way to detect a valid format, since
        // it's just a collection of bytes with no meta data. If I return true,
        // the "Should error on invalid file" test fails
        return ImageReadError.Unsupported;
    }

    pub fn readImage(allocator: Allocator, stream: *ImageUnmanaged.Stream) ImageReadError!ImageUnmanaged {
        if (try stream.getEndPos() % 2 != 0) {
            return ImageReadError.Unsupported;
        }
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var icn = Self{};

        const pixels = try icn.read(allocator, stream);

        result.width = icn.width();
        result.height = icn.height();
        result.pixels = pixels;

        return result;
    }

    pub fn writeImage(allocator: Allocator, write_stream: *ImageUnmanaged.Stream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageWriteError!void {
        _ = write_stream; // autofix
        _ = image; // autofix
        _ = encoder_options;
        _ = allocator;

        // TODO: implement...dithering! or maybe just support indexed1 for now :(
    }

    pub fn width(self: Self) usize {
        return self.icn_width;
    }

    pub fn height(self: Self) usize {
        return self.icn_height;
    }

    pub fn pixelFormat(_: Self) !PixelFormat {
        return PixelFormat.indexed1;
    }

    pub fn read(self: *Self, allocator: Allocator, stream: *ImageUnmanaged.Stream) ImageReadError!color.PixelStorage {
        var buffered_stream = buffered_stream_source.bufferedStreamSourceReader(stream);

        const reader = buffered_stream.reader();

        const pixel_format = try self.pixelFormat();

        const pixels_size: usize = self.width() * self.height();
        var pixels = try color.PixelStorage.init(allocator, pixel_format, pixels_size);
        errdefer pixels.deinit(allocator);

        var tile_buf: [8]u8 = @splat(0);
        for (0..self.height() / 8) |r| {
            for (0..self.width() / 8) |c| {
                _ = try reader.readAtLeast(tile_buf[0..], tile_buf.len);
                drawTile(pixels.indexed1.indices, self.width(), tile_buf[0..], @intCast(c * 8), @intCast(r * 8));
            }
        }

        return pixels;
    }

    fn drawTile(dst: []u1, dst_width: usize, tile: []const u8, x: u32, y: u32) void {
        const size: u8 = 8;
        for (0..size) |v| {
            for (0..size) |h| {
                const ch1 = tile[v] >> @intCast(h) & 1;
                if (ch1 > 0) {
                    const i = (y + v) * dst_width + x + 7 - h;
                    dst[i] = 1;
                }
            }
        }
    }
};
