# Python implementation of the SuperBLT hashing library
# v1.0
# Original Code by fragtrane, https://github.com/fragtrane/Python-SuperBLT-Hash-Calculator

from hashlib import sha256
from os import path, walk


# Calculate SHA-256
def blt_hash(input_data, directory, blocksize=8192):
    a_hash = sha256()
    if directory:
        with open(input_data, "rb") as file:
            buf = file.read(blocksize)
            while len(buf) > 0:
                a_hash.update(buf)
                buf = file.read(blocksize)
    else:
        a_hash.update(input_data)
    return a_hash.hexdigest()


def blt_hash_file(file_path):
    hashed = blt_hash(file_path, True)
    return blt_hash(hashed.encode(), False)


def blt_hash_dir(input_directory):
    hashes = dict()
    for root, dirs, files in walk(input_directory, topdown=True):
        dirs[:] = [d for d in dirs if d != ".git"]
        for file in files:
            file_path = path.join(root, file)
            hashes[file_path.lower().encode("utf-8")] = blt_hash(file_path, True)
    sorted_keys = sorted(hashes.keys())
    joined_hash = ""
    for key in sorted_keys:
        joined_hash = joined_hash + hashes[key]
    return blt_hash(joined_hash.encode(), False)


mods = [
    "./assets/mod_overrides/ShaveHUD Assets",
    "./assets/mod_overrides/ShaveHUD Extras",
    "../../../../Program Files (x86)/Steam/steamapps/common/PAYDAY 2/assets/mod_overrides/Hawk's Complete Soundpack",
    "../../../../Program Files (x86)/Steam/steamapps/common/PAYDAY 2/mods/ShaveHUD"
]

for mod_path in mods:
    path_nodes = mod_path.split("/")
    mod_name = path_nodes[-2] + "/" + path_nodes[-1]

    if path.isfile(mod_path):
        print(mod_name + ": " + blt_hash_file(mod_path))
    elif path.isdir(mod_path):
        print(mod_name + ": " + blt_hash_dir(mod_path))
    else:
        print("ERROR: Invalid Path.")
