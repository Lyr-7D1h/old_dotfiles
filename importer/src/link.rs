use std::path;
use std::io;
use std::fs;

pub fn link(src_dir: &path::PathBuf, dest_dir: &path::PathBuf) -> io::Result<()> {
  link_recurse(src_dir, dest_dir, src_dir)
}

fn link_recurse(src_dir: &path::PathBuf, dest_dir: &path::PathBuf, cur_dir: &path::PathBuf) -> io::Result<()> {
  for entry in cur_dir.read_dir().unwrap() {
    if let Ok(entry) = entry {
        let found_path = entry.path();

        let dest_path = dest_dir.join(
          found_path.strip_prefix(src_dir).unwrap()
        );

        // If file already exists remove
        if dest_path.is_file() {
          fs::remove_file(&dest_path)?;
        }

        if found_path.is_file() {
          println!("{:?} to {:?}", found_path, dest_path);
          fs::hard_link(found_path, dest_path).unwrap();
          // if let Err(err) = fs::hard_link(found_path, dest_path) {
          //   return Err(err);
          // }
        } else if found_path.is_dir() {
          if !dest_path.exists() {
            fs::create_dir(&dest_path)?;
          }

          link_recurse(src_dir, dest_dir, &found_path)?;
        }
    }
  }

  Ok(())
}

