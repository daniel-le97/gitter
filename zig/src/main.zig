const std = @import("std");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

const Repo = struct { path: []const u8, url: []const u8 };
var repos = std.ArrayList(Repo).init(allocator);
// var paths = std.ArrayList([]const u8).init(allocator);

pub fn main() !void {
    const time = std.time.milliTimestamp();
    defer arena.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();
    const file = try std.fs.cwd().openFile("repos.txt", .{ .mode = .read_write });
    defer file.close();
    const home_dir = env.get("HOME") orelse env.get("USERPROFILE") orelse "~/";
    const dot_files = try std.mem.concat(allocator, u8, &.{ home_dir, "/." });
    const lib_files = try std.mem.concat(allocator, u8, &.{ home_dir, "/Library" });

    if (args.len > 1) {
        const command = args[1];
        if (!std.mem.eql(u8, command, "")) {
            try findGitRepos(command, &.{ dot_files, lib_files }, file.writer());
        }
    } else {
        // Fallback to home_dir if no command is provided
        try findGitRepos(home_dir, &.{ dot_files, lib_files }, file.writer());
    }
    var writer = file.writer();

    var index: usize = 1;
    for (repos.items) |r| {
        try writer.print("{d}. {s}\n", .{ index, r.path });
        try writer.print(" - {s}\n", .{r.url});
        allocator.free(r.path);
        allocator.free(r.url);
        index += 1;
    }
    defer repos.deinit();
    std.debug.print("Git repositories found: {d}\n", .{repos.items.len});
    std.debug.print("Elapsed: {d} ms\n", .{std.time.milliTimestamp() - time});
}

fn findGitRepos(dir_path: []const u8, filters: *const [2][]const u8, writer: std.fs.File.Writer) !void {
    var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .directory) {
            continue;
        }
        const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });
        if (std.mem.startsWith(u8, full_path, filters[0])) {
            continue;
        }
        if (std.mem.startsWith(u8, full_path, filters[1])) {
            continue;
        }
        defer allocator.free(full_path);

        if (entry.kind == .directory) {
            if (std.mem.eql(u8, entry.name, ".git")) {
                // std.debug.print("Git repository found: {s}\n", .{dir_path});
                const path_copy = try allocator.dupe(u8, dir_path);
                // try paths.append(path_copy);

                // try writer.print("{s}\n", .{dir_path});
                const config_path = try std.fs.path.join(allocator, &.{ full_path, "config" });

                defer allocator.free(config_path);

                const repo_url = try getGitHubRepoName(config_path);
                const url_copy = try allocator.dupe(u8, repo_url);
                try repos.append(Repo{ .path = path_copy, .url = url_copy });
                // std.debug.print("GitHub URL found: {s}\n", .{repo_name});
            } else {
                // Recursively walk subdirectories
                try findGitRepos(full_path, filters, writer);
            }
        }
    }
}

fn getGitHubRepoName(config_path: []const u8) ![]const u8 {
    var file = std.fs.cwd().openFile(config_path, .{}) catch |e|
        switch (e) {
            error.PathAlreadyExists => {
                return "already exists";
            },
            error.FileNotFound => {
                return "file not found";
            },
            else => return "file not found",
        };

    defer file.close();

    var reader = file.reader();
    var buffer: [1024]u8 = undefined;
    const size = try reader.readAll(buffer[0..]);

    const content = buffer[0..size];
    var lines = std.mem.splitAny(u8, content, "\n"); // Specify the type `u8` as the first argument
    const remoteOriginPrefix = "\turl = ";

    // Look for the remote.origin.url line
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, remoteOriginPrefix)) {
            const url = line[remoteOriginPrefix.len..];
            return url;
        }
    }

    return "not published on GitHub";
}
