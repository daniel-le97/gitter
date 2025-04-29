package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
	// "github.com/charmbracelet/bubbles/table"
	// tea "github.com/charmbracelet/bubbletea"
	// "github.com/charmbracelet/lipgloss"
)

// GitRepo represents a Git repository with its path
type GitRepo struct {
	Path string
}

// // isGitRepo checks if the GitRepo's path is a Git repository
// func (repo *GitRepo) isGitRepo() bool {
// 	gitDir := filepath.Join(repo.Path, ".git")
// 	info, err := os.Stat(gitDir)
// 	return err == nil && info.IsDir()
// }

// // getRemoteURL retrieves the remote URL of the Git repository
// func (repo *GitRepo) getRemoteURL() (string, error) {
// 	cmd := exec.Command("git", "-C", repo.Path, "remote", "get-url", "origin")
// 	output, err := cmd.Output()
// 	if err != nil {
// 		return "", err
// 	}
// 	return strings.TrimSpace(string(output)), nil
// }

// GitScanner is responsible for scanning directories for Git repositories
type GitScanner struct {
	RootDir string
	User    string
}

// scanDirectory scans the directory tree for Git repositories
func (scanner *GitScanner) scanDirectory() []GitRepo {
	var repos []GitRepo
	paths := make(chan string, 100)
	var wg sync.WaitGroup

	// Start worker goroutines
	for i := 0; i < 10; i++ { // Adjust the number of workers as needed
		wg.Add(1)
		go func() {
			defer wg.Done()
			for path := range paths {
				repo := GitRepo{Path: path}
				repos = append(repos, repo)
				// if repo.isGitRepo() {
				// 	remoteURL, err := repo.getRemoteURL()
				// 	if err != nil {
				// 		fmt.Printf("Git Repo: %s\nRemote URL: %s\n\n", path, "Not configured")
				// 	} else {
				// 		if strings.Contains(remoteURL, scanner.User) {
				// 			fmt.Printf("Git Repo: %s\nRemote URL: %s\nisYours: True\n\n", path, remoteURL)
				// 		} else {
				// 			fmt.Printf("Git Repo: %s\nRemote URL: %s\n\n", path, remoteURL)
				// 		}
				// 	}
				// }
			}
		}()
	}

	// Walk the directory tree and send directories to the channel
	err := filepath.Walk(scanner.RootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("Error accessing path %s: %v\n", path, err)
			return nil
		}

		// Skip /Library and hidden directories
		if info.IsDir() {
			if info.Name() == ".git" {
				if strings.Contains(path, scanner.RootDir+"/Library") ||
					strings.Contains(path, scanner.RootDir+"/.") ||
					strings.Contains(path, scanner.RootDir+"/go") {
					// fmt.Println("Skipping directory:", path)
					return filepath.SkipDir
				}
				fmt.Println("Found Git directory:", path)
				paths <- path
			}
			// if strings.HasPrefix(info.Name(), ".") || strings.Contains(path, "/Library") {
			// 	fmt.Println("Skipping directory:", path)
			// 	return filepath.SkipDir
			// }
			// paths <- path
		}
		return nil
	})

	if err != nil {
		fmt.Printf("Error walking the directory tree: %v\n", err)
	}

	// Close the channel and wait for workers to finish
	close(paths)
	wg.Wait()
	return repos
}

// getGitUsername retrieves the global Git username
func getGitUsername() (string, error) {
	cmd := exec.Command("git", "config", "--global", "user.name")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

// getDirectory retrieves the directory from the command-line arguments or defaults to the home directory
func getDirectory() string {
	if len(os.Args) > 1 {
		info, err := os.Stat(os.Args[1])
		if err != nil {
			os.Exit(1)
		}
		if info.IsDir() {
			return os.Args[1]
		}
		os.Exit(1)
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Error getting home directory: %v\n", err)
		os.Exit(1)
	}
	return homeDir
}

func main() {

	start := time.Now()

	// Get the directory from the command-line arguments or use the home directory as default
	dir := getDirectory()

	// Get the Git username
	user, err := getGitUsername()
	if err != nil {
		fmt.Printf("Error getting Git username: %v\n", err)
		return
	}

	// Scan for Git repositories
	scanner := GitScanner{RootDir: dir, User: user}
	repos := scanner.scanDirectory()

	fmt.Printf("Repos found: %d\n", len(repos))
	fmt.Printf("Elapsed time: %s\n", time.Since(start))

}
