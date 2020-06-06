use std::path;
use std::io;
use std::fs;

///
/// Move all files from one directory to another.
/// Wraps recursive function copy_current_dir
///
pub fn copy_dir(src_dir: &path::PathBuf, dest_dir: &path::PathBuf) -> io::Result<()> {
    let orig_dir = src_dir.clone();

    return copy_current_dir(&orig_dir, &dest_dir, &src_dir);
}

fn copy_current_dir(orig_dir: &path::PathBuf, dest_dir: &path::PathBuf, cur_dir: &path::PathBuf) -> io::Result<()> {

    for entry in cur_dir.read_dir()? {
        if let Ok(entry) = entry {
            // println!("Found: {:?}", entry.path());

            // Resolve all symbolic links and get the full absolute path
            let found_path = entry.path();
            let orig_path = orig_dir;

            // println!("{:?} {:?}", found_path, orig_path);

            // New absolute path from config directory
            let new_found_path = dest_dir.join(
                found_path.strip_prefix(
                    orig_path
                ).unwrap()
            );

            if found_path.is_file() {
                // println!("New file path: from {:?} to {:?}",
                //     found_path,
                //     new_found_path
                // );

                match fs::copy(entry.path(), new_found_path) {
                    Ok(_) => (),
                    Err(err) => {
                        return Err(
                            io::Error::new(
                                err.kind(),
                                "could not copy file to backup location"
                            )
                        )
                    }
                }
            } else if found_path.is_dir() {
                // if dir do recurse
                fs::create_dir(new_found_path).unwrap();

                if let Err(err) = copy_current_dir(orig_dir, dest_dir, &found_path) {
                    match err.kind() {
                        io::ErrorKind::NotFound => eprintln!("Could not find: {:?}", found_path),
                        _ => return Err(err)
                    }

                }
            }
        }
    };

    Ok(())
}