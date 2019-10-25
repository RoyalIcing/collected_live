// #[macro_use] extern crate rustler;
// #[macro_use] extern crate rustler_codegen;
// #[macro_use] extern crate lazy_static;

use rustler::{Encoder, Env, NifResult, Term};
// use rustler::{Env, Error, Term};
use rustler::types::{atom};

mod highlight;

// mod atoms {
//     rustler_atoms! {
//         atom ok;
//         //atom error;
//         //atom __true__ = "true";
//         //atom __false__ = "false";
//     }
// }

rustler::rustler_export_nifs! {
    "Elixir.CollectedLive.SyntaxHighlighter.Engine",
    [
        // ("add", 2, add),
        ("highlight_html", 2, highlight_html)
    ],
    None
}

fn highlight_html<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let input: String = args[0].decode()?;
    let extension: String = args[1].decode()?;

    let output = highlight::highlight_html(input, extension);

    Ok((atom::ok(), output).encode(env))
}

// fn add<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
//     let num1: i64 = args[0].decode()?;
//     let num2: i64 = args[1].decode()?;

//     Ok((atom::ok(), num1 + num2).encode(env))
// }
