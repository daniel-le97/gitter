use std::fs;
use std::io::{self, BufRead};
use std::path::Path;
use std::time::Instant;


#[derive(Debug)]
struct Repo {
    path: String,
    url: String,
}

fn find_git_repos(dir: &Path, repos: &mut Vec<Repo>) -> io::Result<()> {
    let home_dir_str: &'static str = env!("HOME");
    let home_dir = Path::new(home_dir_str);
    if dir.is_dir() {
        // Skip $HOME/. and $HOME/Library paths
        // if dir == home_dir.join(".local") || dir.starts_with(home_dir.join("Library")) {
        //     println!("Skipping: {}", dir.display());
        //     return Ok(());
        // }
        if dir == home_dir.join("Library") || dir.file_name().map_or(false, |name| name.to_string_lossy().starts_with('.')) {
            // println!("Skipping: {}", dir.display());
            return Ok(());
        }
        // println!("   dir: {}", dir.display());
        for entry in fs::read_dir(dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.is_dir() {
                if let Some(name) = path.file_name() {
                    if name == ".git" {
                        // if path.starts_with(home_dir.join(".")) || path.starts_with(home_dir.join("Library")) {
                        //     continue;
                        // }
                        // println!("   URL: {}", path.display());
                        let config_path = path.join("config");
                        if config_path.exists() {
                            if let Some(repo_url) = extract_repo_url(&config_path) {
                                repos.push(Repo {
                                    path: path.to_string_lossy().to_string(),
                                    url: repo_url,
                                });
                            }
                        }
                    } else {
                        // continue;
                        find_git_repos(&path, repos)?;
                    }
                }
            }
        }
    }
    Ok(())
}

fn extract_repo_url(config_path: &Path) -> Option<String> {
    if let Ok(file) = fs::File::open(config_path) {
        let reader = io::BufReader::new(file);
        for line in reader.lines() {
            if let Ok(line) = line {
                if line.trim_start().starts_with("url = ") {
                    return Some(line.trim_start_matches("url = ").trim().to_string());
                }
            }
        }
    }
    None
}



fn main() -> io::Result<()> {
    let start = Instant::now(); // Start the timer

    let mut repos = Vec::new();
    let home_dir: &'static str = env!("HOME");
    let home_dir_p = Path::new(home_dir);

    println!("Searching for .git/config files in {:?}...", home_dir_p.join("."));
    find_git_repos(Path::new(home_dir), &mut repos)?;

    for (i, repo) in repos.iter().enumerate() {
        println!("{}. Path: {}", i + 1, repo.path);
        println!("   URL: {}", repo.url);
    }

    println!("Found {} repositories.", repos.len());

    let duration = start.elapsed(); // Calculate elapsed time
    println!("Time taken: {:.2?}", duration); // Print the elapsed time

    Ok(())
}