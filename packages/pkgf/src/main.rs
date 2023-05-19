#![warn(clippy::pedantic)]
#![allow(clippy::uninlined_format_args)]

use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::routing::post;
use axum::{Json, Router, Server};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::time::Duration;

#[tokio::main]
async fn main() {
    let config_path = std::env::var_os("PKGF_CONFIG").expect("$PKGF_CONFIG unset");
    let config: Config = serde_json::from_reader(File::open(config_path).unwrap()).unwrap();

    let app = Router::new()
        .route(&format!("/pkgf/{}", config.secret), post(default_handler))
        .route(&format!("/pkgf/{}/:id", config.secret), post(handler))
        .with_state(AppState::new(config.mapping));
    eprintln!("listening on http://127.0.0.1:3000");
    Server::bind(&([127, 0, 0, 1], 3000).into())
        .serve(app.into_make_service())
        .await
        .unwrap();
}

async fn default_handler(
    State(state): State<AppState>,
    Json(incoming): Json<Incoming>,
) -> StatusCode {
    handler(State(state), Path("default".into()), Json(incoming)).await
}

async fn handler(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(incoming): Json<Incoming>,
) -> StatusCode {
    eprintln!("request received: id={}", id);
    let Some(url) = state.mapping.get(&id) else { return StatusCode::NOT_FOUND };
    let Some(text) = capture(&state, &incoming.text) else { return StatusCode::BAD_REQUEST };
    match send(&state, url, text).await {
        Ok(()) => StatusCode::OK,
        Err(err) => {
            eprintln!("{:?}", err);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

async fn send(state: &AppState, url: &str, text: &str) -> reqwest::Result<()> {
    state
        .client
        .post(url)
        .timeout(Duration::from_secs(15))
        .form(&Outgoing { content: text })
        .send()
        .await?
        .error_for_status()?;
    Ok(())
}

fn capture<'a>(state: &AppState, text: &'a str) -> Option<&'a str> {
    Some(state.regex.captures(text)?.get(0)?.as_str())
}

#[test]
fn test_capture() {
    let state = AppState::new(HashMap::new());

    let result = capture(
        &state,
        "\
Blah blah blah blah

Hello, You received blah blah blah

    Blah: blah

It is ready for pickup now.
Thanks, mgmt",
    );
    assert_eq!(
        result,
        Some("You received blah blah blah\n\n    Blah: blah\n\nIt is ready for pickup now.")
    );
}

#[derive(Deserialize)]
struct Config {
    secret: String,
    mapping: HashMap<String, String>,
}

#[derive(Clone)]
struct AppState {
    client: reqwest::Client,
    regex: Regex,
    mapping: HashMap<String, String>,
}

impl AppState {
    fn new(mapping: HashMap<String, String>) -> AppState {
        AppState {
            client: reqwest::Client::new(),
            regex: Regex::new(r"(?s)You received.*pickup now\.").unwrap(),
            mapping,
        }
    }
}

#[derive(Deserialize)]
struct Incoming {
    text: String,
}

#[derive(Serialize)]
struct Outgoing<'a> {
    content: &'a str,
}
