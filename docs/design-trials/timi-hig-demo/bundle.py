"""Create a portable, offline HTML file from the prototype's three source files."""
from pathlib import Path

root = Path(__file__).resolve().parent
html = (root / "index.html").read_text()
html = html.replace('<link rel="stylesheet" href="style.css">',
                    '<style>\n' + (root / "style.css").read_text() + '\n</style>')
html = html.replace('<script src="app.js"></script>',
                    '<script>\n' + (root / "app.js").read_text() + '\n</script>')
(root / "Timi-Design-Demo.html").write_text(html)
print(root / "Timi-Design-Demo.html")
