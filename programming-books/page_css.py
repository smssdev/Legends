"""The @page rules for one book: trim size, mirrored margins and running heads.

Everything else about the look is in style/book.css.
"""


def page_css(lang, book, chapter_titles):
    rtl = lang == "ar"
    head = "'Cairo', 'Inter', sans-serif" if rtl else "'Inter', sans-serif"
    # The gutter (binding side) is on the inside. A right-to-left book is bound on the right of its
    # first page, so the left/right margins swap.
    inner, outer = "0.875in", "0.625in"
    rec_l, rec_r = (outer, inner) if rtl else (inner, outer)
    named = "".join(
        f"""@page {cid} {{ @top-center {{ content: "{title}"; }} }}
@page {cid}:first {{ @top-center {{ content: none; }} }}
"""
        for cid, title in chapter_titles)
    return f"""
@page {{ size: 7in 10in; margin: 0.8in {rec_r} 0.8in {rec_l};
  @top-center {{ content: "{book["title"][lang]}"; font: 700 8pt {head}; color: #7c3aed; }}
  @bottom-center {{ content: counter(page); font: 700 9pt {head}; color: #fff; background: #4338ca;
    border-radius: 9pt; height: 16pt; width: 26pt; margin-top: 18pt; }} }}
@page :left {{ margin-left: {rec_r}; margin-right: {rec_l}; }}
@page front {{ @top-center {{ content: none; }} @bottom-center {{ content: none; background: none; }} }}
{named}"""
