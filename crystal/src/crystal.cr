require "file"
require "json"
require "env"
require "dir"
require "time"

# # Define a Repo structure
class Repo
  def initialize(path : String, url : String)
    @path = path
    @url = url
  end

  def path
    @path
  end

  def url
    @url
  end
end

# # Function to extract the GitHub URL from a .git/config file
def extract_github_url(config_path : String) : String
  if File.exists?(config_path)
    File.open(config_path, "r") do |file|
      file.each_line do |line|
        if line.starts_with? "\turl = "
          return line[7..-1].strip
        end
      end
    end
  end
  # Return an empty string if no match is found or the file doesn't exist
  "none"
end

# # Function to recursively find Git repositories
def find_git_repos(dir : String, repos : Array(Repo))
  if Dir.exists?(dir)
    Dir.each_child(dir) do |entry|
      path = File.join(dir, entry)
      # puts path
      if path.includes?("brew")
        next
      end
      if Dir.exists?(path)
        if path.ends_with?(".git")
          repos << Repo.new(path, extract_github_url(File.join(path, "config")))
        else
          find_git_repos(path, repos)
        end
      end
    end
  end
end

# Main function
def main
  elapsed_time = Time.measure do
    # Measure the time taken to execute the code
    home_dir = "/Users/daniel/homelab/"
    repos = Array(Repo).new

    puts "Searching for .git/config files in #{home_dir}..."
    find_git_repos(home_dir, repos)

    repos.each_with_index do |repo, index|
      puts "#{index + 1}. #{repo.path}"
      puts " - #{repo.url}"
    end

    puts "Total repositories found: #{repos.size}"
  end
  puts "Elapsed time: #{elapsed_time.milliseconds} ms"
end

main
