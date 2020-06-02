use std::env;

pub struct ImporterArgs {
  srcpath: &'static str,
  destpath: &'static str
}

pub fn get_args() -> Result<ImporterArgs, String> {
  let args: Vec<String> = env::args().collect();

  if args.len() > 1 {
    match args[1].as_str() {
      "-h" => println!("Help"),
      _ => return Err(format!("Invalid option: {}", args[1]))
    }
  }


  for arg in args.iter() {
    println!("{:?}", arg);
  }


  Ok(ImporterArgs {
    srcpath: "/home/lyr/p/dotfiles/importer/test-config/config", 
    destpath: "test-config/new_config",
  })
}