use syntect::parsing::SyntaxSet;
// use syntect::highlighting::{Color, ThemeSet};
use syntect::highlighting::{ThemeSet};
use syntect::html::highlighted_html_for_string;

pub fn highlight_html(input: String, extension: String) -> String {
    let ss = SyntaxSet::load_defaults_newlines();
    let ts = ThemeSet::load_defaults();

    // let style = "
    //     pre {
    //         font-size:13px;
    //         font-family: Consolas, \"Liberation Mono\", Menlo, Courier, monospace;
    //     }";
    // println!("<head><title>{}</title><style>{}</style></head>", &args[1], style);
    let theme = &ts.themes["base16-ocean.dark"];
    let syntax = ss.find_syntax_by_extension(&extension).unwrap_or_else(|| ss.find_syntax_plain_text());;
    // let c = theme.settings.background.unwrap_or(Color::WHITE);
    // println!("<body style=\"background-color:#{:02x}{:02x}{:02x};\">\n", c.r, c.g, c.b);
    let html = highlighted_html_for_string(&input, &ss, &syntax, theme);
    // println!("{}", html);
    // println!("</body>");

    return html
}
