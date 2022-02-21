
use actix_web::*;
use teloxide::prelude::*;
use serde::{Deserialize, Serialize};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    start_actix().await
}

#[derive(Deserialize)]
pub struct ReportJson {
    pub report: String,
    pub when: String
}

#[derive(Serialize)]
pub struct ReportJsonResult {
    pub status: String,
}

#[post("/report")]
async fn reporter(json: web::Json<ReportJson>) -> Result<HttpResponse> {
    send_notify(&json);
    
    Ok(HttpResponse::Ok().json(ReportJsonResult {status: "OK".to_owned()}))
}


async fn start_actix() -> std::io::Result<()> {
    teloxide::enable_logging!();
    HttpServer::new(|| {
        App::new().service(reporter)
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}


// BIG SHIT OF SHITS DONT DO THIS
#[tokio::main]
async fn send_notify(body: &ReportJson) {
    let bot = Bot::from_env().auto_send();
    bot.send_message(637406247, format!("{}\n{}", body.when, body.report)).await.unwrap();
}