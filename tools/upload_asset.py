import hashlib
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

from github import Github

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

api_key = os.getenv("API_KEY", None)
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

repo_name = os.getenv("REPO_NAME", None)
release_name = os.getenv("RELEASE_NAME", None)

logging.info("Starting at %s", current_date)

if not (repo_name and api_key and release_name):
    logging.error(
        "'REPO_NAME'/'API_KEY'/'RELEASE_NAME' not found in your environment vars."
        "please add this and run again."
    )
    sys.exit(1)


gh = Github(api_key)
print(repo_name, api_key)
repo = gh.get_repo(repo_name)

release = repo.get_release(release_name)

logging.info("Statrting upload ISO to release")

release.upload_asset(path=path)
logging.info("ISO uploaded.")

# update release
msg = (
    release.body
    + f"""
| name | sha256 |
| :---: | :---: |
| {file_name} | {hash} |"""
)
logging.info("Starting update release msg with: \n %s" % msg)
release.update_release(name=release.tag_name, message=msg)
logging.info("Release update is done.")
