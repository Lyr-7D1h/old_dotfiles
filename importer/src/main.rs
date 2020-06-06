use importer::Importer;
use importer::args;

use std::io;
use std::process;

fn main() {
    let options = args::ImporterArgs::new().unwrap_or_else(|err| {
        eprintln!("{}", err);
        process::exit(1)
    });
    
    println!("Starting dotfiles importer...");

    let importer = Importer::new(&options).unwrap_or_else(|err| {
        eprintln!("Invalid options: {}", err);
        process::exit(1)
    });
    
    if options.backup {
        match importer.backup() {
            Ok(_) => println!("Backup complete"),
            Err(err) => {
            match err.kind() {
                io::ErrorKind::NotFound => {
                    eprintln!("{}", err);
                        panic!("There is no source file")
                } 
                    _ => {
                        eprintln!("Backup failed: {}", err)
                    }
                }
            }
        }
    }

    println!("Linking files");

    importer.link().unwrap_or_else(|err| {
        println!("Linking failed: {}", err)
    });
}