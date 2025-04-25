#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

void check_git_repo(const char *path, const struct stat *st)
{
    if (S_ISDIR(st->st_mode))
    {
        char git_path[1024];
        snprintf(git_path, sizeof(git_path), "%s/.git", path);

        struct stat git_st;
        if (stat(git_path, &git_st) == 0 && S_ISDIR(git_st.st_mode))
        {
            printf("Git repository found: %s\n", path);

            // Construct the path to the config file
            char config_path[1024];
            snprintf(config_path, sizeof(config_path), "%s/config", git_path);

            FILE *config_file = fopen(config_path, "r");
            if (config_file != NULL)
            {
                char line[1024];
                int in_remote_origin = 0;

                // Read the config file line by line
                while (fgets(line, sizeof(line), config_file) != NULL)
                {
                    // Check if we're in the [remote "origin"] section
                    if (strstr(line, "[remote \"origin\"]") != NULL)
                    {
                        in_remote_origin = 1;
                    }
                    else if (in_remote_origin && strstr(line, "url =") != NULL)
                    {
                        // Extract and print the URL
                        char *url = strchr(line, '=');
                        if (url != NULL)
                        {
                            url++; // Move past the '=' character
                            while (*url == ' ') url++; // Skip leading spaces
                            printf(" - Remote URL: %s", url);
                        }
                        break;
                    }
                    else if (line[0] == '[') // Exit the section if another section starts
                    {
                        in_remote_origin = 0;
                    }
                }

                fclose(config_file);
            }
            else
            {
                perror("Failed to open config file");
            }
        }
    }
}


void walk_directory(const char *base_path)
{
    struct dirent *entry;
    DIR *dir = opendir(base_path);

    if (dir == NULL)
    {
        perror("opendir");
        return;
    }

    char path[1024];
    while ((entry = readdir(dir)) != NULL)
    {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        {
            continue;
        }

        // Check if base_path ends with a '/' and construct the path accordingly
        if (base_path[strlen(base_path) - 1] == '/')
        {
            snprintf(path, sizeof(path), "%s%s", base_path, entry->d_name);
        }
        else
        {
            snprintf(path, sizeof(path), "%s/%s", base_path, entry->d_name);
        }

        struct stat st;
        if (stat(path, &st) == 0 && S_ISDIR(st.st_mode))
        {
            check_git_repo(path, &st);
            walk_directory(path);
        }
    }

    closedir(dir);
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        const char *home_dir = getenv("HOME");
        if (home_dir != NULL)
        {
            printf("using User's home directory: %s\n", home_dir);
        }
        else
        {
            walk_directory("~/");
            return 0;
        }
        walk_directory(home_dir);
        return 0;
    }


    walk_directory(argv[1]);

    return 0;
}