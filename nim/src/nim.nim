import os, times, strutils

# Define the Repo structure
type
    Repo = object
        path: string
        url: string


# Function to extract the GitHub repository URL from a .git/config file
proc getGitHubRepoName(configPath: string): string =
    if not fileExists(configPath):
        return "not published on GitHub"

    let content = readFile(configPath)
    for line in content.splitLines():
        if line.startsWith("\turl = "): # Matches the tab character before "url ="
            return line.split("\turl = ")[1]
    return "not published on GitHub"

# Function to read a directory recursively
proc readDirectoryRecursively(path: string): seq[Repo] =
    let home = getEnv("HOME")
    #  let ok = fileExists(path)
    var entries: seq[Repo] = @[]
    for entry in walkDirRec(path, skipSpecial=true):

      if entry.absolutePath.endsWith(".git/config"):
          if entry.contains("/Library"):
              continue
          if entry.absolutePath.contains(home & "/."):
              continue
          let repoUrl = getGitHubRepoName(entry.absolutePath)
          entries.add(Repo(path: entry.absolutePath, url: repoUrl))
    return entries


# Main procedure
proc main() =
    let startTime = cpuTime()
    let home = getEnv("HOME")
    let ok = home & "/homelab"
    let skipDirs = @[home & "/.", home & "/Library"]
    echo "Searching for .git/config files in ", ok
    # findGitRepos(home, skipDirs)

    let repos = readDirectoryRecursively(ok)
    for index, repo in repos :
        echo index, ". ", repo.path
        echo " - ", repo.url

    echo "Total repositories found: ", repos.len
    let endTime = cpuTime()
    let elapsedTime = endTime - startTime
    echo "Elapsed time: ", elapsedTime, " seconds"
# Run the main procedure
main()
