--[[
    Given an absolute path, returns a list of paths in the filesystem which match
    the given pattern.
    
    The implementation here follows the Rust implementation of glob.

    These are the rules:

    - `?` matches any single character (not `/`)
    - `*` matches any (possibly empty) sequence of characters (not `/`)
    - `**` matches the current directory and arbitrary subdirectories; it must
      form an entire path component on its own (e.g. `a/**/b` is valid, but
      `a**b` is not)
    - `[...]` matches any character inside the brackets; ranges like `[a-z]`
      are supported, ordered by Unicode code point
    - `[!...]` matches any character NOT inside the brackets
    - Metacharacters can be matched literally by wrapping them in brackets,
      e.g. `[?]` matches a literal `?`, `[*]` matches a literal `*`
]]
return require("@self/glob")
