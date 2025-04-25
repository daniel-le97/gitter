package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)


// GitRepo represents a Git repository with its path
type GitRepo struct {
	Path string
}

// isGitRepo checks if the GitRepo's path is a Git repository
func (repo *GitRepo) isGitRepo() bool {
	gitDir := filepath.Join(repo.Path, ".git")
	info, err := os.Stat(gitDir)
	return err == nil && info.IsDir()
}

// getRemoteURL retrieves the remote URL of the Git repository
func (repo *GitRepo) getRemoteURL() (string, error) {
	cmd := exec.Command("git", "-C", repo.Path, "remote", "get-url", "origin")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

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
			if strings.HasPrefix(info.Name(), ".") || strings.Contains(path, "/Library") {
				return filepath.SkipDir
			}
			paths <- path
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



var baseStyle = lipgloss.NewStyle().
	BorderStyle(lipgloss.NormalBorder()).
	BorderForeground(lipgloss.Color("240"))

type model struct {
	table table.Model
}

func (m model) Init() tea.Cmd { return nil }


type editorFinishedMsg struct{ err error }

func openEditor(path string) tea.Cmd {
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "code"
	}
	c := exec.Command(editor, path) //nolint:gosec
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return editorFinishedMsg{err}
	})
}


func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "esc":
			if m.table.Focused() {
				m.table.Blur()
			} else {
				m.table.Focus()
			}
		case "q", "ctrl+c":
			return m, tea.Quit
		case "enter":
			url := m.table.SelectedRow()[1]
			return m, tea.Batch(
				tea.Printf("opening %s!", url),
				openEditor(url),
			)
		}
	}
	m.table, cmd = m.table.Update(msg)
	return m, cmd
}

func (m model) View() string {
	return baseStyle.Render(m.table.View()) + "\n"
}


// buildTableRows creates table rows from the list of Git repositories
func buildTableRows(repos []GitRepo, user string) []table.Row {
    var rows []table.Row
	counter := 0
    for _, repo := range repos {
        if repo.isGitRepo() {
            remoteURL, err := repo.getRemoteURL()
            if err != nil {
                remoteURL = "Not configured"
            }

            isYours := "False"
            if strings.Contains(remoteURL, user) {
                isYours = "True"
            }
			counter++
            rows = append(rows, table.Row{
                fmt.Sprint(counter), // Row number
                repo.Path,         // Repository path
                remoteURL,         // Remote URL
                isYours,           // Ownership status
            })
        }
    }
    return rows
}

// displayTable creates and renders the table
func displayTable(columns []table.Column, rows []table.Row) {
    t := table.New(
        table.WithColumns(columns),
        table.WithRows(rows),
        table.WithFocused(true),
        table.WithHeight(25),
    )

    // Apply table styles
    s := table.DefaultStyles()
    s.Header = s.Header.
        BorderStyle(lipgloss.NormalBorder()).
        BorderForeground(lipgloss.Color("240")).
        BorderBottom(true).
        Bold(false)
    s.Selected = s.Selected.
        Foreground(lipgloss.Color("229")).
        Background(lipgloss.Color("57")).
        Bold(false)
    t.SetStyles(s)

    // Run the TUI program
    m := model{t}
    if _, err := tea.NewProgram(m).Run(); err != nil {
        fmt.Println("Error running program:", err)
        os.Exit(1)
    }
}


func main() {
    // Define table columns
    columns := []table.Column{
        {Title: "#", Width: 4},
        {Title: "Path", Width: 100},
        {Title: "URL", Width: 100},
        {Title: "Is Yours", Width: 10},
    }

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

    // Build table rows
    rows := buildTableRows(repos, user)

    // Display elapsed time
    fmt.Printf("Elapsed time: %s\n", time.Since(start))

    // Create and display the table
    displayTable(columns, rows)
}