//! Just a simple test of @[Redux.compose]

int main(int argc, array(string) argv)
{
  function(string:string) reverse_to_upper_x3 =
    Redux.compose(
      lambda (string x) {
        return x*3;
      },
      upper_case,
      reverse);

  // Should output: TOOWTOOWTOOW
  werror("-> %O\n", reverse_to_upper_x3("Woot"));

  return 0;
}
