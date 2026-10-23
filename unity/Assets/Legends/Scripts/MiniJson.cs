using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace Legends
{
    /// <summary>
    /// A small JSON reader for the match feed, so the project needs no package to read what the server sends.
    /// Objects become Dictionary&lt;string, object&gt;, arrays List&lt;object&gt;, numbers long or double.
    /// </summary>
    public static class MiniJson
    {
        public static object Parse(string json)
        {
            var p = new Parser(json);
            var value = p.Value();
            p.Space();
            if (p.Pos != json.Length) throw new FormatException("Extra text after JSON at " + p.Pos);
            return value;
        }

        sealed class Parser
        {
            readonly string s;
            public int Pos;

            public Parser(string json) { s = json; }

            public void Space()
            {
                while (Pos < s.Length && char.IsWhiteSpace(s[Pos])) Pos++;
            }

            public object Value()
            {
                Space();
                if (Pos >= s.Length) throw new FormatException("Unexpected end of JSON");
                char c = s[Pos];
                if (c == '{') return Obj();
                if (c == '[') return Arr();
                if (c == '"') return Str();
                if (c == 't') { Expect("true"); return true; }
                if (c == 'f') { Expect("false"); return false; }
                if (c == 'n') { Expect("null"); return null; }
                return Num();
            }

            void Expect(string word)
            {
                if (string.CompareOrdinal(s, Pos, word, 0, word.Length) != 0) throw new FormatException("Bad JSON at " + Pos);
                Pos += word.Length;
            }

            Dictionary<string, object> Obj()
            {
                var d = new Dictionary<string, object>();
                Pos++;
                Space();
                if (s[Pos] == '}') { Pos++; return d; }
                while (true)
                {
                    Space();
                    string key = Str();
                    Space();
                    if (s[Pos] != ':') throw new FormatException("Expected : at " + Pos);
                    Pos++;
                    d[key] = Value();
                    Space();
                    if (s[Pos] == ',') { Pos++; continue; }
                    if (s[Pos] == '}') { Pos++; return d; }
                    throw new FormatException("Expected , or } at " + Pos);
                }
            }

            List<object> Arr()
            {
                var list = new List<object>();
                Pos++;
                Space();
                if (s[Pos] == ']') { Pos++; return list; }
                while (true)
                {
                    list.Add(Value());
                    Space();
                    if (s[Pos] == ',') { Pos++; continue; }
                    if (s[Pos] == ']') { Pos++; return list; }
                    throw new FormatException("Expected , or ] at " + Pos);
                }
            }

            string Str()
            {
                if (s[Pos] != '"') throw new FormatException("Expected string at " + Pos);
                Pos++;
                var sb = new StringBuilder();
                while (true)
                {
                    char c = s[Pos++];
                    if (c == '"') return sb.ToString();
                    if (c != '\\') { sb.Append(c); continue; }
                    char e = s[Pos++];
                    switch (e)
                    {
                        case 'n': sb.Append('\n'); break;
                        case 't': sb.Append('\t'); break;
                        case 'r': sb.Append('\r'); break;
                        case 'b': sb.Append('\b'); break;
                        case 'f': sb.Append('\f'); break;
                        case 'u':
                            sb.Append((char)Convert.ToInt32(s.Substring(Pos, 4), 16));
                            Pos += 4;
                            break;
                        default: sb.Append(e); break;   // \" \\ \/
                    }
                }
            }

            object Num()
            {
                int start = Pos;
                while (Pos < s.Length && "+-0123456789.eE".IndexOf(s[Pos]) >= 0) Pos++;
                string n = s.Substring(start, Pos - start);
                if (n.Length == 0) throw new FormatException("Bad JSON at " + start);
                if (n.IndexOfAny(new[] { '.', 'e', 'E' }) < 0) return long.Parse(n, CultureInfo.InvariantCulture);
                return double.Parse(n, CultureInfo.InvariantCulture);
            }
        }

        // Helpers for reading the parsed tree without casts everywhere.
        public static Dictionary<string, object> Obj(object o, string key)
        {
            return (o as Dictionary<string, object>) != null && ((Dictionary<string, object>)o).TryGetValue(key, out var v)
                ? v as Dictionary<string, object> : null;
        }

        public static List<object> Arr(object o, string key)
        {
            return (o as Dictionary<string, object>) != null && ((Dictionary<string, object>)o).TryGetValue(key, out var v)
                ? v as List<object> : null;
        }

        public static string Str(object o, string key, string fallback = "")
        {
            return (o as Dictionary<string, object>) != null && ((Dictionary<string, object>)o).TryGetValue(key, out var v) && v != null
                ? Convert.ToString(v, CultureInfo.InvariantCulture) : fallback;
        }

        public static long Int(object o, string key, long fallback = 0)
        {
            return (o as Dictionary<string, object>) != null && ((Dictionary<string, object>)o).TryGetValue(key, out var v) && v != null
                ? Convert.ToInt64(v, CultureInfo.InvariantCulture) : fallback;
        }
    }
}
