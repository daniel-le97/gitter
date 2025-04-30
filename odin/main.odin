package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import "base:runtime"

// variables
repos := [dynamic]Repo{}

// structs
Repo :: struct {
	path: string,
	url:  string,
}

// functions
read_directory_recursively :: proc(path: string) -> ([]os.File_Info, os.Error) {
	dir_handle, err := os.open(path)
	if err != nil {
		fmt.printf("Error opening directory %s: %v\n", path, err)
		return nil, err
	}
	defer os.close(dir_handle)

	entries, read_err := os.read_dir(dir_handle, -1)
	if read_err != nil {
		fmt.printf("Error reading directory %s: %v\n", path, read_err)
		return nil, read_err
	}
	return entries, nil
}

find_git_configs :: proc(path: string) {
	entries, err := read_directory_recursively(path)
	if err != nil {
		fmt.printf("Error reading directory %s: %v\n", path, err)
		return
	}

	home := os.get_env("HOME")
	skip := strings.concatenate([]string{home, "/."})

	for entry in entries {
		if entry.is_dir {
			if strings.starts_with(entry.fullpath, skip) {
				// Skip hidden directories
				continue
			}
			if ODIN_OS_STRING == "darwin" {
				library_path := strings.concatenate([]string{home, "/Library"})
				if strings.starts_with(entry.fullpath, library_path) {
					// Skip private directories
					continue
				}
			}

			find_git_configs(entry.fullpath) // Recurse into subdirectories
		} else if entry.name == "config" && strings.ends_with(entry.fullpath, "/.git/config") {
			// fmt.printf("Found .git/config: %s\n", entry.fullpath)
			content, err := os.read_entire_file(entry.fullpath)
			if !err {
				fmt.printf("Error reading file %s: %v\n", entry.fullpath, err)
			}

			content_str := string(content)
			content_str_lines := strings.split(content_str, "\n")
			repo_url := "not found"
			for line in content_str_lines {
				filter := "\turl = "
				if strings.starts_with(line, filter) {
					//   fmt.printf("Remote found in %s: %s\n", entry.fullpath, line)
					repo_url = strings.trim(line, filter)
				}
			}
			// fmt.printfln("Content of %s:\n%s", entry.fullpath, content_str)
			append_elem(&repos, Repo{path = entry.fullpath, url = repo_url})
		}
	}
}

main :: proc() {
	stopwatch := time.Stopwatch{}
	time.stopwatch_start(&stopwatch)
	home := os.get_env("HOME")
	if home == "" {
		fmt.printf("HOME environment variable is not set.\n")
		return
	}

	fmt.printf("Searching for .git/config files in %s...\n", home)
	// fmt.printfln(ODIN_OS_STRING)
	find_git_configs(home)
	// for repo, i in repos {
	// 	fmt.println(i + 1, "-", repo.path)
	// 	fmt.println("\t", repo.url)
	// }
	elapsed := time.stopwatch_duration(stopwatch)
	fmt.printf("Elapsed time: %v\n", elapsed)
}
