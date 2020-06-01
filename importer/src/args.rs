use std::env;

struct ImporterArgs {
  destpath: String,
  srcpath: String
}

pub mod args {
  pub fn get_args() -> ImporterArgs {
    let args: Vec<String> = env::args().collect();

    ImporterArgs {
      srcdir: "/home/lyr/p/dotfiles/importer/test-config/config", 
      destpath: "test-config/new_config",
    }
  }
}