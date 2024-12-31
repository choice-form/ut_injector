# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      inject_function: 1,
      inject_function: 2,
      inject_macro: 1,
      inject_macro: 2
    ]
  ]
]
