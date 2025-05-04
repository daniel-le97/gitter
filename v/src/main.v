module main

import os
import time

struct Repo {
mut:
	path string
	url  string
}

fn get_remote_url(path string) string {
	content := os.read_file(path) or {
		println('Error reading file: ${err}')
		return ''
	}
	mut remote_url := 'none'
	for line in content.split_into_lines() {
		if line.contains('\turl =') {
			remote := line.all_after('\turl = ')
			if remote != '' {
				remote_url = remote
			}
		}
	}
	return remote_url
}

fn get_walk_path() !string {
	if os.args.len < 1 {
		return error('please provide a path to search for git repositories')
	}
	walk_path := os.args[1]
	if !os.exists(walk_path) {
		return error('${walk_path} does not exist')
	}
	if !os.is_dir(walk_path) {
		return error('${walk_path} is not a directory')
	}
	return walk_path
}

fn main() {
	timer := time.new_stopwatch()
	//
	mut repos := &[]Repo{}

	walk_path := get_walk_path() or { panic(err) }
	
	handler := fn [mut repos] (path string) {
		if path.ends_with('/.git/config') {
			repos << Repo{
				path: path.all_before('/.git/config')
				url:  get_remote_url(path)
			}
		}
	}

	os.walk(walk_path, handler)

	for repo in repos {
		println('Path: ${repo.path}')
		println('URL: ${repo.url}')
	}

	println(repos.len)
	println(timer.elapsed())
}
