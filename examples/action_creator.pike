
//! Implements @[Redux.Action]
private class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("(%O => %O)", type, payload);
  }
}


//! Do we call this IICE?
object my_actions = class {
  constant INC = "inc";
  constant DEC = "dec";

  Redux.Action inc(int payload) {
    return action(INC, payload);
  }

  Redux.Action dec(int payload) {
    return action(DEC, payload);
  }
}();


int main(int argc, array(string) argv)
{
  Redux.Store store = Redux.create_store(reducer, ([]));

  // Bind a single creator
  Redux.ActionFunction inc =
    Redux.bind_action_creator(
      lambda (int payload) {
        return action("inc", 7);
      },
      store->dispatch
    );

  //! Now, this is the same as @tt{store->dispatch(action("inc", 12))@}
  inc(12);

  // Bind multiple creators via a class instance
  mapping(string:Redux.ActionFunction) action =
    Redux.bind_action_creators(my_actions, store->dispatch);

  action->inc(12);
  action->dec(5);

  return 0;
}

Redux.State reducer(Redux.State state, Redux.Action action)
{
  werror("reducer: action -> %O\n", action);
  return state;
}
