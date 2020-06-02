use importer::Importer;
use std::io;
use std::process;

mod args;

fn main() {
    let options = args::get_args().unwrap_or_else(|err| {
        eprintln!("{}", err);
        process::exit(1)
    });
    
    println!("Starting dotfiles importer");

    let importer = Importer::new("/home/lyr/p/dotfiles/importer/test-config/config", "test-config/new_config").unwrap_or_else(|err| {
        eprintln!("Invalid options: {}", err);
        process::exit(1)
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