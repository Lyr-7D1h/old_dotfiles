use importer::Importer;
use std::io;
use std::env;

fn main() {
    println!("Starting dotfiles importer");

    let importer = Importer::new("/home/lyr/p/dotfiles/importer/test-config/config", "test-config/new_config").unwrap_or_else(|err| {
        panic!("Invalid options: {}", err)
    });
    
    importer.backup().unwrap_or_else(|err| {
        match err.kind() {
           io::ErrorKind::NotFound => {
                panic!("There is no source file")
           } 
            _ => {
                eprintln!("Backup failed: {}", err)
            }
        }
    });

    println!("Linking files");

    importer.link().unwrap_or_else(|err| {
        println!("Linking failed: {}", err)
    });
}
