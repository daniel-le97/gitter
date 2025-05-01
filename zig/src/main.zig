const std = @import("std");

var gpu = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpu.allocator();

// var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// const allocator = arena.allocator();

const Repo = struct { path: []const u8, url: []const u8 };
var repos = std.ArrayList(Repo).init(allocator);
var filters_array = std.ArrayList([]u8).init(allocator);

pub fn main() !void {
    const start_time = std.time.milliTimestamp();
    defer {
        filters_array.deinit(); // This frees all items in the array
        repos.deinit(); // This frees all items in the repos array
        const deinit_status = gpu.deinit();

        // we should never leak memory otherwise we have a bug
        if (deinit_status == .leak) std.debug.assert(true);
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    const home_dir = env.get("HOME") orelse env.get("USERPROFILE").?;
    std.debug.assert(home_dir > 0);

    const dot_filter = try std.fs.path.join(allocator, &.{ home_dir, "." });
    const library_filter = try std.fs.path.join(allocator, &.{ home_dir, "Library" });
    const go_filter = try std.fs.path.join(allocator, &.{ home_dir, "go" });
    try filters_array.append(dot_filter);
    try filters_array.append(library_filter);
    try filters_array.append(go_filter);
    defer {
        allocator.free(go_filter);
        allocator.free(dot_filter);
        allocator.free(library_filter);
    }

    const search_dir = if (args.len > 1 and !std.mem.eql(u8, args[1], "")) args[1] else home_dir;
    try findGitRepos(search_dir, filters_array.items);

    const file = try std.fs.cwd().openFile("repos.txt", .{ .mode = .read_write });
    defer file.close();

    var writer = file.writer();
    var index: usize = 0;
    for (repos.items) |repo| {
        try writer.print("{d}. {s}\n - {s}\n", .{ index + 1, repo.path, repo.url });
        allocator.free(repo.path);
        allocator.free(repo.url);
        index += 1;
    }

    std.debug.print("Git repositories found: {d}\n", .{repos.items.len});
    std.debug.print("Elapsed: {d} ms\n", .{std.time.milliTimestamp() - start_time});
}

fn findGitRepos(dir_path: []const u8, filters: [][]u8) !void {
    var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    outer: while (try it.next()) |entry| {
        if (entry.kind != .directory) continue;

        const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });
        defer allocator.free(full_path);

        for (filters) |filter| {
            if (std.mem.startsWith(u8, full_path, filter)) continue :outer;
        }

        if (std.mem.eql(u8, entry.name, ".git")) {
            try processGitRepo(dir_path, full_path);
        } else {
            try findGitRepos(full_path, filters);
        }
    }
}

fn processGitRepo(dir_path: []const u8, git_path: []const u8) !void {
    const path_copy = try allocator.dupe(u8, dir_path);
    const config_path = try std.fs.path.join(allocator, &.{ git_path, "config" });
    defer allocator.free(config_path);

    const repo_url = try getGitHubRepoName(config_path);
    const url_copy = try allocator.dupe(u8, repo_url);

    try repos.append(Repo{ .path = path_copy, .url = url_copy });
}

fn getGitHubRepoName(config_path: []const u8) ![]const u8 {
    var file = std.fs.cwd().openFile(config_path, .{}) catch |e| {
        return switch (e) {
            error.PathAlreadyExists, error.FileNotFound => "file not found",
            else => "file not found",
        };
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
