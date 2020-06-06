use std::env;
use std::path;

pub struct ImporterArgs {
  pub srcpath: path::PathBuf,
  pub destpath: path::PathBuf,
  pub backup: bool,
}

impl ImporterArgs {
  fn default() -> ImporterArgs {
    let dot_files_path  = match env::current_dir() {
      Err(_) => panic!("Could not fetch current working directory"),
      Ok(value) => value.parent().unwrap().canonicalize().unwrap()
    };

    let home_path = match env::var("HOME") {
      Err(_) => panic!("Could not find home directory"),
      Ok(value) => value
    };

    let mut destpath = path::PathBuf::from(home_path);
    destpath.push(".config");

    ImporterArgs {
      srcpath: dot_files_path,
      destpath: destpath,
      backup: true
    }
  }

  pub fn new() -> Result<ImporterArgs, String> {
    let args: Vec<String> = env::args().collect();

    let mut importer_args = ImporterArgs::default();

    if args.len() > 1 {
      match args[1].as_str() {
        "-h" => return Err(String::from("Help")),
        "--no-backup" => importer_args.backup = false,
        "-t" => {
          println!("Using test paths..");
          importer_args.srcpath = path::PathBuf::from("test-config/new_config");
          importer_args.destpath = path::PathBuf::from("test-config/config");
        },
        _ => return Err(format!("Invalid option: {}", args[1]))
      }
    } else {
    }

    Ok(importer_args)
  }
}