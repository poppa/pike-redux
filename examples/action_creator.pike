
//! Implements @[Redux.Action]
private class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("%O(%O => %O)", object_program(this), type, payload);
  }
}


class my_actions {
  constant INC = "inc";
  constant DEC = "dec";

  Redux.Action inc(int payload) {
    return action(INC, payload);
  }

  Redux.Action dec(int payload) {
    return action(DEC, payload);
  }
}


int main(int argc, array(string) argv)
{
  Redux.Store store = Redux.create_store(reducer, Redux.State(0));

  // Bind a single creator
  function inc =
    Redux.bind_action_creator(
      lambda (int payload) {
        return action("inc", payload);
      },
      store->dispatch
    );

  //! Now, this is the same as @tt{store->dispatch(action("inc", 12))@}
  inc(12);

  // Bind multiple creators via a class instance
  mapping(string:function) action =
    Redux.bind_action_creators(my_actions, store->dispatch);

  action->inc(12);
  action->dec(5);

  werror("State: %O\n", store->get_state());

  return 0;
}

Redux.State reducer(Redux.State state, Redux.Action action)
{
  werror("reducer(%O): action -> %O\n", state, action);

  switch (action->type)
  {
    case my_actions.INC:
      werror("INC...\n");
      state = state + action->payload;
      break;

    case my_actions.DEC:
      werror("DEC...\n");
      state = state - action->payload;
      break;
  }

  return state;
}
