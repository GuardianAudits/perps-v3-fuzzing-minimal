#![deny(clippy::all)]

#[macro_use]
extern crate napi_derive;

use napi::Error;
use solang_parser::lexer::Lexer;
use solang_parser::pt::Comment as SComment;
use std::result::Result;

#[napi(object)]
pub struct Comment {
    pub start: u32,
    pub end: u32,
    pub text: String,
}

#[napi(object)]
pub struct AnalysisResult {
  pub comments: Vec<Comment>,
}

#[napi]
pub fn analyze(input: String) -> Result<AnalysisResult, Error> {
  let mut comments = Vec::new();
  let lexer = Lexer::new(&input, 0, &mut comments);
lexer.for_each(drop);

  let comments: Vec<_> = comments.into_iter().filter_map(|c| {
      if let SComment::Line(loc, text) | SComment::Block(loc, text) = c {
          let start: u32 = loc.start().try_into().unwrap();
          let end: u32 = loc.end().try_into().unwrap();
          Some(Comment { start, end, text })
      } else {
          None
      }
  }).collect();

  let res = AnalysisResult {
      comments,
  };

  Ok(res)
}
