const std = @import("std");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse args into string array
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <command> [options]\n", .{args[0]});
        return;
    }

    const command = args[1];
    if (std.mem.eql(u8, command, "greet")) {
        if (args.len < 3) {
            std.debug.print("Usage: {s} greet <name>\n", .{args[0]});
            return;
        }
        const name = args[2];
        std.debug.print("Hello, {s}!\n", .{name});
    } else if (std.mem.eql(u8, command, "help")) {
        std.debug.print("Available commands:\n", .{});
        std.debug.print("  greet <name>  - Greet the specified name\n", .{});
        std.debug.print("  git-repos --dir <path> - List all Git repositories in the specified directory\n", .{});
        std.debug.print("  help          - Show this help message\n", .{});
    } else if (std.mem.eql(u8, command, "git-repos")) {
        if (args.len < 4 or !std.mem.eql(u8, args[2], "--dir")) {
            std.debug.print("Usage: {s} git-repos --dir <path>\n", .{args[0]});
            return;
        }
        const dir_path = args[3];
        try findGitRepos(dir_path);
        std.debug.print("finished\n", .{});
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.debug.print("Use '{s} help' to see available commands.\n", .{args[0]});
    }
}

fn findGitRepos(dir_path: []const u8) !void {
    var stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator(); // Use the allocator() method

    var fs = std.fs.cwd();
    const dir = try fs.openDir(dir_path, .{ .iterate = true });

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.name });
        defer allocator.free(full_path);

        if (entry.kind == .directory) {
            if (std.mem.eql(u8, entry.name, ".git")) {
                try stdout.print("Git repository found: {s}\n", .{dir_path});
                const config_path = try std.fs.path.join(allocator, &.{ full_path, "config" });
                defer allocator.free(config_path);

                const repo_name = try getGitHubRepoName(config_path);
                try stdout.print("GitHub repository found: {s}\n", .{repo_name});
            } else {
                // Recursively walk subdirectories
                try findGitRepos(full_path);
            }
        }
    }
}

fn getGitHubRepoName(config_path: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(config_path, .{});
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