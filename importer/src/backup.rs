use std::path;
use std::io;
use std::fs;

///
/// If file from src_dir exists in dest_dir copy the file from dest_dir to bak_dir
///
pub fn backup_existing_files
(
    src_dir: &path::PathBuf, 
    dest_dir: &path::PathBuf, 
    bak_dir: &path::PathBuf) 
-> io::Result<()> {
    backup_existing_current_dir(src_dir, dest_dir, bak_dir, src_dir.clone())
}

fn backup_existing_current_dir
(
    src_dir: &path::PathBuf, 
    dest_dir: &path::PathBuf, 
    bak_dir: &path::PathBuf, 
    cur_dir: path::PathBuf
) -> io::Result<()> {
    for entry in cur_dir.read_dir().unwrap() {
        if let Ok(entry) = entry {
            let found_path = entry.path();

            let relative_file_path = found_path.strip_prefix(src_dir).unwrap(); 

            let dest_path = dest_dir.join(
                relative_file_path
            );
            let bak_path = bak_dir.join(
                relative_file_path
            );

            if found_path.is_file() {
                if dest_path.exists() && dest_path.is_file() {
                    println!("Copying {:?} to {:?}", dest_path, bak_path);
                    match fs::copy(dest_path, bak_path) {
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
                }
            } else if found_path.is_dir() {
                if dest_path.exists() && dest_path.is_dir() {
                    fs::create_dir(&bak_path).unwrap();
                    backup_existing_current_dir(src_dir, dest_dir, bak_dir, found_path)?;
                }
            }
        }
    }

    Ok(())
}