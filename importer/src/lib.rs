use std::fs;
use std::path;
use std::io;

mod copy;

pub struct Importer {
    destpath: path::PathBuf,
    srcpath: path::PathBuf
}

impl Importer {
    pub fn new(destpath: &str, srcpath: &str) -> Result<Importer, String> {
        let importer = Importer {
            destpath: path::PathBuf::from(destpath),
            srcpath: path::PathBuf::from(srcpath)
        };

        importer.validate()?;

        Ok(importer)
    }

    fn validate(&self) -> Result<(), &str> {
        if ! &self.destpath.is_dir() {
            return Err("Destination path in not a directory")
        }
        if ! &self.srcpath.is_dir() {
            return Err("Source path in not a directory")
        }

        Ok(())
    }

    pub fn backup(&self) -> io::Result<()> {
        let mut backup_path = self.destpath.with_file_name("config-backup");

        let mut file_extension = 0;
        loop {
            let error = fs::create_dir(&backup_path).err();

            match error {
                None => {
                    break; 
                },
                Some(err) => {
                    if err.kind() == io::ErrorKind::AlreadyExists {
                        let file_name ;
                        if file_extension > 0 {
                            file_name = format!("config-backup{}", file_extension);
                        } else {
                            file_name = String::from("config-backup");
                        }

                        backup_path.set_file_name(file_name);
                        file_extension += 1;
                    } else {
                        println!("{}", err);
                        return Err(
                            io::Error::new(err.kind(), "could not create backup directory")
                        );
                    }
                }
            }
        }

        println!("Copying from {} to {}", &self.destpath.display(), backup_path.display());

        copy::copy_dir(&self.destpath, &backup_path)
    }

    pub fn link(&self) -> std::io::Result<()> {
        // Hard link
        Ok(())
    }
}