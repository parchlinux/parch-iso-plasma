import hashlib
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

from github import Github

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

api_key = os.getenv("api_key", None)
current_date = datetime.today().strftime("%Y-%m-%d")


def _compute_sha256(file_name):
    hash_sha256 = hashlib.sha256()
    with open(file_name, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_sha256.update(chunk)
    return hash_sha256.hexdigest()


_path = list(Path().cwd().glob("out/*.iso"))[0]
path = _path.as_posix()

file_name = _path.name

hash = _compute_sha256(path)

repo_name = os.getenv("name", None)
release_name = os.getenv("release_name", None)

logging.info("Starting at %s", current_date)

if not (repo_name and api_key and release_name):
    logging.error(
        "'repo_name'/'api_key'/'release_name' not found in your envs."
        "please add this and run again"
    )
    sys.exit(1)


gh = Github(api_key)
print(repo_name, api_key)
repo = gh.get_repo(f"parchlinux/{repo_name}")

release = repo.get_release(release_name)

logging.info("statrting Upload ISO to release")

release.upload_asset(path=path)
logging.info("ISO upload is done")

# update release
msg = (
    release.body
    + f"""
| name | sha256 |
| :---: | :---: |
| {file_name} | {hash} |"""
)
logging.info("Starting Update release msg with: \n %s" % msg)
release.update_release(name=release.tag_name, message=msg)
logging.info("Release Update is done.")
