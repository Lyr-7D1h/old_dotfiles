use importer::backup;

fn main() {
    println!("Starting dotfiles importer");
    backup().unwrap_or_else(|err| {
        println!("Backup failed: {}", err)
    })
}
