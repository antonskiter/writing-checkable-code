import os
import shutil


def build(src, out):
    """Make out a copy of src."""
    os.makedirs(out, exist_ok=True)
    for name in os.listdir(src):
        shutil.copyfile(os.path.join(src, name), os.path.join(out, name))
    return sorted(os.listdir(out))
