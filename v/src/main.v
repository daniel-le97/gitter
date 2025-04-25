module main

import os

import time

struct Repo {
mut:
	path string
	url  string
}

fn file_adder() fn (path string) []string {
	mut files_ := []string{}
	func := fn [mut files_] (path string) []string {
		if path == '' {
			return files_
		}
		files_ << path
		return files_
	}
	return func
}

fn get_git_user() string {
	cmd := os.execute('git config --global user.name')
	if cmd.exit_code != 0 {
		return ''
	}
	return cmd.output
}


const files = file_adder()

const user = get_git_user()


struct App {
	mut:
		files []string
		repos []Repo
		user  string
}



fn main() {

	timer := time.new_stopwatch()
	mut repos := []Repo{}

	os.walk(os.home_dir(), fn (path string) {
		if path.ends_with('/.git/config') {
			files(path)
		}
	})

	for file in files('') {
		println(file)
		lines := os.read_lines(file) or {
			println('Error reading file: ${err}')
			return
		}
		mut remote_url := 'none'
		for line in lines {
			if line.contains('\turl =') {
				// println(line)
				remote := line.all_after('\turl = ')
				if remote != '' {
					remote_url = remote
				}
			}

		}
		repos << Repo{
			path: file.all_before('/.git/config')
			url:  remote_url
		}
	}

	

	println(repos.len)
	println(timer.elapsed())
}
