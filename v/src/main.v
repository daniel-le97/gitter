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

fn main() {
	timer := time.new_stopwatch()
	mut repos := &[]Repo{}

	path := if os.args.len > 1 {
		os.args[1]
	} else {
		os.home_dir()
	}


	handler := fn [mut repos]( path string) {
		if path.ends_with('/.git/config') {
			repos << Repo{
				path: path.all_before('/.git/config')
				url:  get_remote_url(path)
			}	
		}
	}

	os.walk(path, handler)


	for repo in repos {
		println('Path: ${repo.path}')
		println('URL: ${repo.url}')
	}

	println(repos.len)
	println(timer.elapsed())
}
