use claude_sdk_rs::{Client, Config};
use std::path::Path;
use std::env;
use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    // Use Claude Code environment variables instead of JSON parsing
    let file_paths = env::var("CLAUDE_FILE_PATHS")
        .unwrap_or_else(|_| String::new());
    let tool_output = env::var("CLAUDE_TOOL_OUTPUT")
        .unwrap_or_else(|_| String::new());
    let project_dir = env::var("CLAUDE_PROJECT_DIR")
        .unwrap_or_else(|_| env::current_dir().unwrap().to_string_lossy().to_string());
    
    println!("🔧 Claude Code PostToolUse Hook");
    println!("📁 Project Directory: {}", project_dir);
    
    if file_paths.is_empty() {
        println!("⚠️  No file paths provided");
        return Ok(());
    }
    
    // Initialize Claude SDK client
    let client = Client::new(Config::default());
    
    // Process each file
    for file_path in file_paths.split_whitespace() {
        println!("\n📄 Processing: {}", file_path);
        
        // Apply smart cleanup based on file type
        apply_smart_cleanup(file_path).await?;
        
        // Analyze file with Claude if tool output is available
        if !tool_output.is_empty() {
            analyze_with_claude(&client, file_path, &tool_output).await?;
        }
    }
    
    println!("\n✅ Enhanced hook processed successfully");
    Ok(())
}

async fn analyze_with_claude(client: &Client, file_path: &str, tool_output: &str) -> Result<()> {
    let analysis_prompt = format!(
        "Analyze this {} file change for code quality and suggest improvements:\n\nTool Output: {}\nFile: {}",
        get_file_type(file_path),
        tool_output,
        file_path
    );
    
    match client.query(&analysis_prompt).send().await {
        Ok(analysis) => {
            println!("🤖 Claude Analysis:");
            println!("{}", analysis);
        }
        Err(e) => {
            eprintln!("⚠️  Claude analysis failed: {}", e);
        }
    }
    
    Ok(())
}

fn get_file_type(file_path: &str) -> &str {
    match Path::new(file_path).extension().and_then(|ext| ext.to_str()) {
        Some("rs") => "Rust",
        Some("js") | Some("ts") => "JavaScript/TypeScript", 
        Some("py") => "Python",
        Some("json") => "JSON",
        Some("toml") => "TOML",
        Some("md") => "Markdown",
        _ => "text",
    }
}

async fn apply_smart_cleanup(file_path: &str) -> Result<()> {
    // Remove trailing whitespace (basic cleanup)
    let sed_result = std::process::Command::new("sed")
        .args(&["-i", "", "s/[[:space:]]*$//"])
        .arg(file_path)
        .output();
    
    match sed_result {
        Ok(output) if output.status.success() => {
            println!("🧹 Removed trailing whitespace");
        }
        Ok(output) => {
            eprintln!("⚠️  sed failed: {}", String::from_utf8_lossy(&output.stderr));
        }
        Err(e) => {
            eprintln!("⚠️  Failed to run sed: {}", e);
        }
    }
    
    // Apply language-specific formatting
    match get_file_type(file_path) {
        "Rust" => {
            if let Ok(output) = std::process::Command::new("rustfmt")
                .arg(file_path)
                .output() 
            {
                if output.status.success() {
                    println!("🦀 Applied rustfmt formatting");
                }
            }
        }
        "JSON" => {
            // Could add jq formatting here
            println!("📋 JSON file detected");
        }
        _ => {}
    }
    
    Ok(())
}