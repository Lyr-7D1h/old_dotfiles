use std::fs;

pub fn backup() -> std::io::Result<()> {
    fs::copy("test.txt", "test1.txt")?;
    Ok(())
}
