#!/usr/bin/env python3

import subprocess
import os
import datetime
from termcolor import colored


def get_git_log():
    """Get git log and return the output as a string."""
    try:
        # Get git log with pretty formatting
        log_format = "%h|%an|%ad|%s"
        cmd = ["git", "log", f"--pretty=format:{log_format}", "--date=iso"]

        # Execute
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error getting git log: {e}")
        return None


def write_to_file(content, file_path="commits.log"):
    """Write content to the specified file."""
    try:
        # Create directories
        os.makedirs(os.path.dirname(file_path), exist_ok=True)

        with open(file_path, "w") as f:
            # Add header
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"# Git Commit Log - Generated on {timestamp}\n")
            f.write("# Format: hash|author|date|message\n\n")
            f.write(content)

        print(f"Successfully wrote git log to {file_path}")
        return True
    except Exception as e:
        print(f"Error writing to file: {e}")
        return False


def main():

    try:
        repo_root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()

        os.chdir(repo_root)
        print(f"Changed to repository root: {repo_root}")
    except subprocess.CalledProcessError as e:
        print(f"Error finding repository root: {e}")
        return

    # Get git log
    git_log = get_git_log()

    if git_log:
        output_file = os.path.join(repo_root, "commits.log")

        write_to_file(git_log, output_file)
    else:
        print("No git log retrieved. Exiting.")


if __name__ == "__main__":
    main()
